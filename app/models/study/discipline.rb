class Study::Discipline < ActiveRecord::Base
  STUDY_START = { 2013 => { 1 => Date.new(2013,  9,  4), 2 => Date.new(2014,  1,  13)} }
  STUDY_END   = { 2013 => { 1 => Date.new(2013, 12, 31), 2 => Date.new(2014,  6,  30) } }
  CURRENT_STUDY_YEAR  = 2013
  CURRENT_STUDY_TERM  = 2

  self.table_name = 'subject'

  alias_attribute :id,       :subject_id
  alias_attribute :name,     :subject_name
  alias_attribute :semester, :subject_semester
  alias_attribute :year,     :subject_year
  alias_attribute :brs,      :subject_brs

  belongs_to :group, foreign_key: :subject_group

  belongs_to :lead_teacher, class_name: User, foreign_key: :subject_teacher

  has_many :discipline_teachers, class_name: Study::DisciplineTeacher,
           primary_key: :subject_id, foreign_key: :subject_id, dependent: :destroy
  accepts_nested_attributes_for :discipline_teachers, allow_destroy: true, reject_if: proc { |attrs| attrs[:teacher_id].blank? }

  has_many :assistant_teachers, through: :discipline_teachers

  [[:lectures, Study::Checkpoint::TYPE_LECTURE], [:seminars, Study::Checkpoint::TYPE_SEMINAR],
   [:checkpoints, Study::Checkpoint::TYPE_CHECKPOINT]].each do |lessons|
    has_many lessons[0], -> { where(checkpoint_type: lessons[1]).order(:checkpoint_date) },
             class_name: Study::Checkpoint, foreign_key: :checkpoint_subject, dependent: :destroy
    accepts_nested_attributes_for lessons[0], allow_destroy: true
  end

  has_many :classes, -> { order(:checkpoint_date) }, class_name: Study::Checkpoint, foreign_key: :checkpoint_subject

  has_many :exams, class_name: Study::Exam, foreign_key: :exam_subject, dependent: :destroy
  accepts_nested_attributes_for :exams, allow_destroy: true

  has_one :validation, -> { where(exam_type: Study::Exam::TYPE_VALIDATION)}, class_name: Study::Exam, foreign_key: :exam_subject, dependent: :destroy

  has_one :final_exam, -> { where(exam_type: Study::Exam::EXAMS_TYPES.collect{|x| x[1]}) }, class_name: Study::Exam, foreign_key: :exam_subject, dependent: :destroy, inverse_of: :discipline
  accepts_nested_attributes_for :final_exam

  has_many :additional_exams, -> { where(exam_type: Study::Exam::ADDITIONAL_EXAMS_TYPES.collect{|x| x[1]}) },
           class_name: 'Study::Exam', foreign_key: :exam_subject, dependent: :destroy
  accepts_nested_attributes_for :additional_exams, allow_destroy: true

  has_one :semester_work, -> { where(exam_type: Study::Exam::TYPE_SEMESTER_WORK)}, 
          class_name: Study::Exam, foreign_key: :exam_subject
  has_one :semester_project, -> { where(exam_type: Study::Exam::TYPE_SEMESTER_PROJECT)}, 
          class_name: Study::Exam, foreign_key: :exam_subject
  

  validates :name, presence: true
  validates :year, presence: true, numericality: { greater_than: 2010, less_than: 2020 }
  validates :semester, presence: true, inclusion: { in: [1,2] }
  validates :lead_teacher, presence: true
  validates :group, presence: true
  validate  :sum_of_checkpoints_max_values_should_be_80
  validate  :sum_of_checkpoints_min_values_should_be_44

  default_scope do
    order(subject_year: :desc, subject_semester: :desc)
  end

  scope :from_name, -> name { where('subject_name LIKE :prefix', prefix: "#{name}%")}
  scope :from_student, -> student {where(subject_group:  student.group)}
  scope :from_group, -> group {where(subject_group: group)}

  scope :by_term, -> year, term {
    where(subject_year: year, subject_semester: term)
  }
  scope :now, -> { by_term(CURRENT_STUDY_YEAR, CURRENT_STUDY_TERM) }

  scope :include_teacher, -> user {
    if user.is?(:subdepartment_assistant)
      # Определяем его кафедру.
      dep_ids = user.positions.from_role(:subdepartment_assistant.to_s).map { |p| p.department.id }
      users = User.in_department(dep_ids).with_role(Role.select(:acl_role_id).where(acl_role_name: ['lecturer', 'subdepartment']))
      ids = users.map { |u| u.id }.push(user.id)

      includes(:assistant_teachers).references(:assistant_teachers)
      .where('subject_teacher IN (?) OR subject_teacher.teacher_id IN (?)', ids, ids).references(:subject_teacher)
    elsif user.is?(:subdepartment)
      # Определяем его кафедру.
      dep_ids = user.positions.from_role(:subdepartment.to_s).map { |p| p.department.id }
      users = User.in_department(dep_ids).with_role(Role.select(:acl_role_id).where(acl_role_name: ['lecturer', 'subdepartment']))
      ids = users.map { |u| u.id }.push(user.id)
      includes(:assistant_teachers).references(:assistant_teachers)
      .where('subject_teacher IN (?) OR subject_teacher.teacher_id IN (?)', ids, ids).references(:subject_teacher)
    else
      includes(:assistant_teachers).references(:assistant_teachers)
      .where('subject_teacher = ? OR subject_teacher.teacher_id = ?', user.id, user.id).references(:subject_teacher)
    end
  }

  scope :with_brs, ->{where(subject_brs:  true)}

  def has?(type)
    work = (type == 'work' ? 2 : 3)
    exams.where(exam_type: work) != []
  end

  def control
    exams.where(exam_type: [0,1,9]).first
  end

  def current_ball
    l1, p1, n1 = 0.0, 0.0, 0.0
    l = lectures.count
    p = seminars.count
    if l == 0
      sum_p = 20.0
      sum_l = 0.0
    elsif p == 0
      sum_p = 0.0
      sum_l = 20.0
    else
      sum_p = 15.0
      sum_l = 5.0
    end
    classes.each do |checkpoint|
      unless checkpoint.date.future?
        l1 += (sum_l/l) if checkpoint.lecture?
        p1 += (sum_p/p) if checkpoint.seminar?
        if checkpoint.is_checkpoint?
          n1 += (checkpoint.max? ? checkpoint.max : 0.0)
        end
      end
    end
    (l1+p1+n1).round 2
  end

  def is_active?
    year == CURRENT_STUDY_YEAR
    #case CURRENT_STUDY_TERM
    #  when 1
    #    year == CURRENT_STUDY_YEAR || (year == CURRENT_STUDY_YEAR - 1 && semester == 2)
    #  when 2
    #    year == CURRENT_STUDY_YEAR
    #end
  end

  def brs?
    classes.any?
  end

  def not_brs?
    classes.empty?
  end

  def add_semester_work
    exams.create(exam_type: Study::Exam::TYPE_SEMESTER_WORK)
    save!
  end
  def add_semester_project
    exams.create(exam_type: Study::Exam::TYPE_SEMESTER_PROJECT)
  end

  def destroy_semester_work
    semester_work.destroy
    save!
  end
  def destroy_semester_project
    semester_project.destroy
    save!
  end

  private

  def sum_of_checkpoints_max_values_should_be_80
    return true if checkpoints.length == 0
    max_sum = 0
    checkpoints.each do |c|
      max_sum += c.max unless c.marked_for_destruction?
    end
    if 80 != max_sum
      errors.add(:'checkpoints.max',
                 "Сумма максимальных баллов должна равняться 80. У вас — #{max_sum}.")
    end
  end

  def sum_of_checkpoints_min_values_should_be_44
    return true if checkpoints.length == 0
    min_sum = 0
    checkpoints.each do |c|
      min_sum += c.min unless c.marked_for_destruction?
    end
    if 44 != min_sum
      errors.add(:'checkpoints.min',
                 "Сумма минимальных зачётных баллов должна равняться 44. У вас — #{min_sum}.")
    end
  end
end