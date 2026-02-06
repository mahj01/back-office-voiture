package org.itu;

import com.itu.*;
import com.util.MultipartFile;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import com.util.Session;

@ControllerAnnotation(url="classe3")
public class Class3 {

    @UrlAnnotation(url="hello")
    public String hello() {
        return "Hello world";
    }

    @UrlAnnotation(url="echo")
    public String echo(String message) {
        return "Echo: " + message;
    }

    @UrlAnnotation(url="withRequest")
    public void handle(HttpServletRequest req, HttpServletResponse res) throws IOException {
        res.getWriter().write("Direct response");
    }

    @UrlAnnotation(url = "test")
    public ModelView testView(){
        return new ModelView("/test.jsp");
    }

    @UrlAnnotation(url = "testData")
    public ModelView testDataView() {
        ModelView withData = new ModelView("/testData.jsp");
        withData.addAttribute("message1","Bonjour");
        return withData;
    }

    @UrlAnnotation(url = "testData/{name}")
    public ModelView testDataDynamic(HttpServletRequest request) {
        String name = (String) request.getAttribute("name");
        ModelView mv = new ModelView("/testData.jsp");
        mv.addAttribute("message1", "Sent the name " + name);
        return mv;
    }

    @UrlAnnotation(url = "testData2/{name}")
    public ModelView testDataDynamic2(@RequestParam("name") String name) {
        ModelView mv = new ModelView("/testData.jsp");
        mv.addAttribute("message1", "Sent the name " + name);
        return mv;
    }

    @GetMapping
    @UrlAnnotation(url = "testData3/{name}")
    public ModelView testDataDynamic3(String name) {
        ModelView mv = new ModelView("/testData.jsp");
        mv.addAttribute("message1", "Sent the name " + name);
        return mv;
    }

    @GetMapping
    @UrlAnnotation(url = "testDatas")
    public ModelView testDatas(Session session) {
        ModelView mv = new ModelView("/testDatas.jsp");
        session.get("userId");
        return mv;
    }

    @PostMapping
    @UrlAnnotation(url = "testData4")
    public ModelView testDataDynamic4(HashMap<String, Object> map) {
        ModelView mv = new ModelView("/testResult.jsp");
        mv.addAttribute("dataMap", map);
        return mv;
    }
    @GetMapping
    @UrlAnnotation(url = "testEntityForm")
    public ModelView testEntity() {
        ModelView mv = new ModelView("/testEntityForm.jsp");
        return mv;
    }

    @PostMapping
    @UrlAnnotation(url = "testEntity")
    public ModelView testEntity(Employe emp) {
        ModelView mv = new ModelView("/testEntity.jsp");
        mv.addAttribute("employe", emp);
        return mv;
    }

    @JsonAnnotation
    @PostMapping
    @UrlAnnotation(url = "testEntityJson")
    public ModelView testEntityJson(Employe emp) {
        ModelView mv = new ModelView("/testEntityJson.jsp");
        mv.addAttribute("employe", emp);
        return mv;
    }

    @GetMapping
    @UrlAnnotation(url = "uploadForm")
    public ModelView uploadForm() {
        return new ModelView("/testUpload.jsp");
    }


    @PostMapping
    @UrlAnnotation(url = "upload")
    public ModelView uploadFiles(MultipartFile[] files) {
        ModelView mv = new ModelView("/uploadResult.jsp");
        List<String> saved = new ArrayList<>();
        if (files != null) {
            for (MultipartFile f : files) {
                if (f == null) continue;
                String original = f.getOriginalFilename();
                if (original == null || original.isBlank()) continue;
                // create a simple unique filename to avoid collisions
                String safeName = System.currentTimeMillis() + "-" + Paths.get(original).getFileName().toString();
                try {
                    Path path = f.saveToUploads(safeName);
                    saved.add(path.toString());
                } catch (java.io.IOException e) {
                    saved.add("ERROR saving " + original + ": " + e.getMessage());
                }
            }
        }
        mv.addAttribute("savedFiles", saved);
        return mv;
    }

    @GetMapping
    @UrlAnnotation(url ="/login")
    public ModelView login() {
        // Show a simple login form where the user can enter their credentials
        return new ModelView("/login.jsp");
    }

    @PostMapping
    @UrlAnnotation(url = "/loginpost")
    public ModelView loginPost(HashMap<String, Object> form, Session session) {
        // Expect form fields: username, password, role (optional)
        String username = form.get("username") == null ? null : form.get("username").toString();
        String password = form.get("password") == null ? null : form.get("password").toString();
        String role = form.get("role") == null ? "user" : form.get("role").toString();

        // Very simple "authentication": accept any non-empty username
        if (username != null && !username.isBlank()) {
            User user = new User(username, password, role);
            session.set("user", user);
            // store a simple userId (use username for now)

        }

        ModelView mv = new ModelView("/profile.jsp");
        mv.addAttribute("user", session.get("user"));
        return mv;
    }



}
