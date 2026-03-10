package org.itu.controller;

import com.itu.ControllerAnnotation;
import com.itu.ModelView;
import com.itu.UrlAnnotation;

@ControllerAnnotation(url = "")
public class HomeController {
    @UrlAnnotation(url = "/")
    public ModelView home() {
        return new ModelView("/index.jsp");
    }
}
