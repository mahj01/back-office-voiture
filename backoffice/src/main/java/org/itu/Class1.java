package org.itu;

import com.itu.ControllerAnnotation;
import com.itu.GetMapping;
import com.itu.ModelView;
import com.itu.UrlAnnotation;
import com.util.Session;
import com.security.Authorized;
import com.security.Role;

@ControllerAnnotation(url="classe1")
public class Class1 {

    @UrlAnnotation(url="testMethod")
    public void testMethod(){

    }

    @GetMapping
    @UrlAnnotation(url = "/profile")
    @Authorized
    public ModelView profile(Session session) {
        ModelView mv = new ModelView("/profile.jsp");
        mv.addAttribute("user", session.get("user"));
        return mv;
    }

    @GetMapping
    @UrlAnnotation(url = "/admin")
    @Role("admin,manager")
    public ModelView admin(Session session) {
        ModelView mv = new ModelView("/admin.jsp");
        mv.addAttribute("user", session.get("user"));
        return mv;
    }
}
