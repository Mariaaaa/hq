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

/* $Id: SVGConstants.java 746664 2009-02-22 12:40:44Z jeremias $ */

package org.apache.fop.render.svg;

import org.apache.xmlgraphics.util.QName;

import org.apache.fop.apps.MimeConstants;
import org.apache.fop.util.XMLConstants;

/**
 * Constants for the intermediate format.
 */
public interface SVGConstants extends XMLConstants {

    /** MIME type for SVG. */
    String MIME_TYPE = MimeConstants.MIME_SVG;

    /** MIME type for SVG Print. */
    String MIME_SVG_PRINT = MimeConstants.MIME_SVG + ";profile=print";

    /** File extension for SVG. */
    String FILE_EXTENSION_SVG = "svg";

    /** XML namespace for SVG. */
    String NAMESPACE = "http://www.w3.org/2000/svg";

    /** the SVG element */
    QName SVG_ELEMENT = new QName(NAMESPACE, null, "svg");

}
