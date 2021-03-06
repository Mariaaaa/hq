class Study::PlansController < ApplicationController
  def index
    authorize! :index, :plans

    @faculties = Department.faculties
    unless current_user.is?(:developer)
      user_departments = current_user.departments_ids
      @faculties = @faculties.find_all { |f| user_departments.include?(f.id) }
    end

    @specialities = Speciality.where(speciality_faculty: @faculties.map { |f| f.id })
    @groups = Group.where(group_speciality: @specialities.map { |s| s.id })

    if current_user.is?(:developer)
      @group = Group.find(params[:group]) if params[:group]
    else
      if params[:group]
        @group = Group.find(params[:group])
        unless user_departments.include?(@group.speciality.faculty.id)
          redirect_to study_plans_path
        end
      end
    end


  end

  def updatedate
    @exam = Study::Exam.find(params[:exam_id])
    @exam.update date: params[:date]
    respond_to do |format|
      format.js
    end
  end

  def updatediscipline

  end

end