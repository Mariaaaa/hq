/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* $Id: PDFNull.java 1228243 2012-01-06 16:03:44Z cbowditch $ */

package org.apache.fop.pdf;

import java.io.IOException;
import java.io.OutputStream;

/**
 * Class representing a PDF name object.
 */
public final class PDFNull implements PDFWritable {

    /** Instance for the "null" object. */
    public static final PDFNull INSTANCE = new PDFNull();

    /**
     * Creates a new PDF name object.
     */
    private PDFNull() {
    }

    /** {@inheritDoc} */
    @Override
    public String toString() {
        return "null";
    }

    /** {@inheritDoc} */
    public void outputInline(OutputStream out, StringBuilder textBuffer) throws IOException {
        textBuffer.append(toString());
    }

}
