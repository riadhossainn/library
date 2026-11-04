<%@ page contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.io.*, java.net.*, java.nio.charset.StandardCharsets, java.util.concurrent.ConcurrentHashMap" %>
<%!
    private static final ConcurrentHashMap<String, String> cache = new ConcurrentHashMap<>();
    
    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }

    private String extractContent(String json) {
        try {
            int start = json.indexOf("\"content\":\"");
            if (start == -1) return null;
            start += 11;
            
            StringBuilder content = new StringBuilder();
            boolean escaped = false;
            for (int i = start; i < json.length(); i++) {
                char c = json.charAt(i);
                if (escaped) {
                    if (c == '"') content.append("\"");
                    else if (c == 'n') content.append("\n");
                    else if (c == 'r') content.append("\r");
                    else if (c == 't') content.append("\t");
                    else if (c == '\\') content.append("\\");
                    else content.append(c);
                    escaped = false;
                } else if (c == '\\') {
                    escaped = true;
                } else if (c == '"') {
                    break;
                } else {
                    content.append(c);
                }
            }
            return content.toString().trim();
        } catch (Exception e) {
            return null;
        }
    }

    public String callGroq(String apiKey, String prompt, int maxTokens) {
        HttpURLConnection conn = null;
        try {
            URL url = new URL("https://api.groq.com/openai/v1/chat/completions");
            conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Authorization", "Bearer " + apiKey);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(60000);
            conn.setDoOutput(true);

            // ✅ UPDATED TO 120B MODEL (Much smarter, follows rules perfectly)
            String payload = "{\"model\":\"openai/gpt-oss-120b\","
                + "\"messages\":["
                + "{\"role\":\"system\",\"content\":\"You are a precise librarian. Follow formatting instructions exactly. Do not add extra text.\"},"
                + "{\"role\":\"user\",\"content\":\"" + escapeJson(prompt) + "\"}"
                + "],"
                + "\"temperature\":0.2,\"max_tokens\":" + maxTokens + "}";

            try (OutputStream os = conn.getOutputStream()) {
                os.write(payload.getBytes(StandardCharsets.UTF_8));
            }

            int code = conn.getResponseCode();
            InputStream stream = (code == 200) ? conn.getInputStream() : conn.getErrorStream();
            StringBuilder sb = new StringBuilder();
            try (BufferedReader br = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
                String line;
                while ((line = br.readLine()) != null) sb.append(line);
            }

            if (code == 200) {
                return extractContent(sb.toString());
            }
        } catch (Exception e) {
            System.out.println("Groq API Error: " + e.getMessage());
        } finally {
            if (conn != null) conn.disconnect();
        }
        return null;
    }
%>
<%
    if (!"student".equals(session.getAttribute("role"))) {
        out.print("{\"content\":\"Unauthorized\"}");
        return;
    }

    String apiKey = null;
    try { apiKey = application.getInitParameter("groq.api.key"); } catch (Exception e) { }
    
    if (apiKey == null || apiKey.isEmpty() || apiKey.contains("YOUR_REAL")) {
        apiKey = "your key "; 
    }

    String type   = request.getParameter("type");
    String title  = request.getParameter("title");
    String author = request.getParameter("author");
    String cat    = request.getParameter("category");

    if (type == null || title == null || author == null) {
        out.print("{\"content\":\"ERROR: Missing parameters\"}");
        return;
    }

    String cacheKey = type + "|" + title + "|" + author;
    String cached = cache.get(cacheKey);
    if (cached != null && cached.length() > 30) {
        out.print("{\"content\":\"" + cached.replace("\\","\\\\").replace("\"","\\\"").replace("\n","<br>") + "\"}");
        return;
    }

    String result;
    if ("recommend".equals(type)) {
        String prompt = "Recommend exactly 3 real books similar to '" + title + "' by " + author + " in the " + cat + " category. " +
            "You MUST output ONLY this exact format, with no other text:\n" +
            "Similar books you might enjoy:\n" +
            "1. [Book Title] by [Author]\n" +
            "2. [Book Title] by [Author]\n" +
            "3. [Book Title] by [Author]";
        
        result = callGroq(apiKey, prompt, 300);
        
        if (result == null || result.length() < 50 || !result.contains("1.")) {
            result = "Similar books you might enjoy in the " + cat + " category:\n1. [Classic Book 1] by [Author]\n2. [Classic Book 2] by [Author]\n3. [Classic Book 3] by [Author]";
        }
    } else {
        String prompt = "Write a clear 5-8 line summary of the book '" + title + "' by " + author + ". " +
            "Explain the main theme, target audience, and key benefits. " +
            "Provide ONLY the final summary. Do not show any reasoning.";
        
        result = callGroq(apiKey, prompt, 600);
        
        if (result == null || result.length() < 50) {
            result = "'" + title + "' by " + author + " is a highly regarded work offering valuable insights into " + 
                     (cat != null ? cat.toLowerCase() : "its subject") + ". It combines theoretical foundations with practical strategies, " +
                     "making it an excellent resource for students and professionals.";
        }
    }

    if (result != null && result.length() > 30) {
        cache.put(cacheKey, result);
    }

    out.print("{\"content\":\"" + result.replace("\\","\\\\").replace("\"","\\\"").replace("\n","<br>") + "\"}");
%>