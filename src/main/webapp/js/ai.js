// NVIDIA API Configuration
const NVIDIA_API_CONFIG = {
    apiKey: "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",
    baseUrl: "https://integrate.api.nvidia.com/v1/chat/completions",
    model: "google/gemma-2-2b-it"
};

// Get book summary from NVIDIA API
async function getBookSummary(title, author) {
    try {
        const prompt = `Provide a concise 2-3 sentence summary of the book '${title}' by ${author}. Focus on the main theme, target audience, and key benefits. Keep it informative and engaging.`;
        
        const response = await fetch(NVIDIA_API_CONFIG.baseUrl, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${NVIDIA_API_CONFIG.apiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                model: NVIDIA_API_CONFIG.model,
                messages: [{ role: 'user', content: prompt }],
                temperature: 0.2,
                top_p: 0.7,
                max_tokens: 150
            })
        });
        
        if (!response.ok) {
            throw new Error(`API Error: ${response.status}`);
        }
        
        const data = await response.json();
        return data.choices[0].message.content;
    } catch (error) {
        console.error('Error getting book summary:', error);
        return `This book '${title}' by ${author} provides valuable insights about its subject matter. It's an excellent choice for readers interested in this topic.`;
    }
}

// Get book recommendations from NVIDIA API
async function getBookRecommendations(title, category) {
    try {
        const prompt = `Suggest 3 books similar to '${title}' in the ${category} category. Format as: 'Similar books you might enjoy: [book1], [book2], [book3]'`;
        
        const response = await fetch(NVIDIA_API_CONFIG.baseUrl, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${NVIDIA_API_CONFIG.apiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                model: NVIDIA_API_CONFIG.model,
                messages: [{ role: 'user', content: prompt }],
                temperature: 0.2,
                top_p: 0.7,
                max_tokens: 100
            })
        });
        
        if (!response.ok) {
            throw new Error(`API Error: ${response.status}`);
        }
        
        const data = await response.json();
        return data.choices[0].message.content;
    } catch (error) {
        console.error('Error getting book recommendations:', error);
        return `Similar books you might enjoy: 'Advanced ${title}', 'Introduction to ${category}', 'Mastering ${title} Concepts'`;
    }
}

// Toggle book summary
async function toggleSummary(bookId) {
    const summaryDiv = document.getElementById(`summary-${bookId}`);
    const button = event.target;
    
    if (summaryDiv.style.display === 'none') {
        // Show loading state
        summaryDiv.innerHTML = '<strong>About this book:</strong><br><em>Loading summary...</em>';
        summaryDiv.style.display = 'block';
        button.textContent = '❌ Loading...';
        
        // Get summary from API
        const title = document.querySelector(`[data-book-id="${bookId}"]`).getAttribute('data-title');
        const author = document.querySelector(`[data-book-id="${bookId}"]`).getAttribute('data-author');
        
        const summary = await getBookSummary(title, author);
        summaryDiv.innerHTML = `<strong>About this book:</strong><span class="ai-badge">AI</span><br>${summary}`;
        button.textContent = '❌ Hide Summary';
    } else {
        summaryDiv.style.display = 'none';
        button.textContent = '📄 Show Summary';
    }
}

// Toggle book recommendations
async function toggleRecommendations(bookId) {
    const recDiv = document.getElementById(`recommendations-${bookId}`);
    const button = event.target;
    
    if (recDiv.style.display === 'none') {
        // Show loading state
        recDiv.innerHTML = '<strong>You might also like:</strong><br><em>Loading recommendations...</em>';
        recDiv.style.display = 'block';
        button.textContent = '❌ Loading...';
        
        // Get recommendations from API
        const title = document.querySelector(`[data-book-id="${bookId}"]`).getAttribute('data-title');
        const category = document.querySelector(`[data-book-id="${bookId}"]`).getAttribute('data-category');
        
        const recommendations = await getBookRecommendations(title, category);
        recDiv.innerHTML = `<strong>You might also like:</strong><br>${recommendations}`;
        button.textContent = '❌ Hide Recommendations';
    } else {
        recDiv.style.display = 'none';
        button.textContent = '📚 Show Recommendations';
    }
}

// Initialize all book cards with data attributes
document.addEventListener('DOMContentLoaded', function() {
    // This will be handled by the JSP template
});