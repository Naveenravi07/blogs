+++
title = "Mastering Error Handling in JavaScript: Common Mistakes and Best Practices"
date = 2025-01-02

taxonomies.tags = [
    "Programmming",
    "Technology",
]
+++

Error handling is one of the most critical yet often overlooked aspects of software development.Poor error management can lead to 
confusing bugs, hard-to-maintain code, and a terrible user experience. In this blog, we’ll look at common mistakes developers 
make while handling errors and discuss best practices to handle them effectively.

<!--more-->

---

# The Usual Suspects: Common Mistakes  

<img style="height:400px" src="https://i.imgflip.com/9fg8hr.jpg" alt="Error Handling Meme" style="margin: 20px 0;" />

### 1. Catching and Re-Throwing Errors Without Adding Value  

Why are you even here if all you’re doing is catching the error to throw it back like a bored middle schooler?  

```javascript
try {  
    const response = await fetch("https://api.example.com/data");  
    return response.json();  
} catch (error) {  
    throw error; // You’ve done nothing. Congrats.  
}  
```

This isn’t clever. It’s redundant, noisy, and accomplishes exactly nothing.  

---

### 2. Swallowing Errors Like They Don’t Matter  

This one’s a classic: catch an error, then do absolutely nothing with it.  

```javascript
try {  
    riskyOperation();  
} catch (error) {  
    // Silence is golden, but not here.  
}  
```

You’ve just made debugging someone else’s nightmare. Hope that’s what you wanted.  

---

### 3. Overloading Error Messages  

Ever seen an error that reads like an essay? Too much verbosity makes the error more confusing than helpful.  

```javascript
throw new Error("Error in fetchUser: User ID not provided. Please ensure you pass a valid user ID to the API call or your program will fail catastrophically.");  
```

Chill out. Errors should be concise but meaningful.  

---

### 4. Mixing Error Handling With Business Logic  

If your function does both the job it’s supposed to and moonlights as a janky error handler, you’re doing it wrong.  

```javascript
async function getUser(id) {  
    try {  
        if (!id) throw new Error("Invalid ID");  
        const user = await db.findById(id);  
        if (!user) throw new Error("User not found");  
        return user;  
    } catch (error) {  
        throw error;  
    }  
}  
```

Messy, cluttered, and just sad to look at.  

---

# The Right Way: Best Practices  

### 1. Set Up a Global Error Handler  

Rule zero: Never handle errors in the controller or service layer of your application. Instead setup a global error handler
and let that handles all the errors. Now you can peacefully throw errors from service or controller layer of 
your application. And yes this introduces some kind of limitations but its totally worth. Your code looks so much cleaner,
readable and maintainable.

For example in Express js you can setup a global error handler like this. 
```javascript
app.use((err, req, res, next) => {  
    console.error(err.stack);  
    res.status(err.status || 500).json({  
        message: err.message || "Internal Server Error",  
    });  
});  
```

---

### 2. Use Dedicated Error Classes  

Don’t overthink this—libraries like `http-errors` exist for a reason. Use them to make custom error handling less painful.  

```javascript
async function getUser(id) {  
    const user = await db.findById(id);  
    if (!user) throw new NotFoundError("User not found");  
    return user;  
}  
```

---

### 3. Log Errors Thoughtfully  

Logging everything like you’re hoarding digital clutter? Bad idea. Log what matters, with context.  

```javascript
try {  
    // Code that might explode  
} catch (error) {  
    console.error({  
        message: error.message,  
        stack: error.stack,  
        context: "Fetching user data",  
    });  
    throw error;  
}  
```  

---

### 4. Separate Expected and Unexpected Errors  

Expected errors deserve meaningful responses. Unexpected ones? Log them, monitor them, and move on.  

```javascript
try {  
    const data = riskyOperation();  
} catch (error) {  
    if (error instanceof ValidationError) {  
        res.status(400).json({ message: error.message });  
    } else {  
        console.error(error);  
        res.status(500).json({ message: "Internal Server Error" });  
    }  
}  
```

---

### 5. Chain Promises Correctly  

For promises, `.catch` isn’t optional—it’s required.  

```javascript
fetch("https://api.example.com/data")  
    .then(response => response.json())  
    .catch(error => console.error("Failed to fetch data:", error));  
```

---

### 6. Use Tools, Not Hacks  

Stop reinventing the wheel. Use tools like **winston** for logging or **Sentry** for error monitoring.  

---

## TL;DR  

Error handling is a cornerstone of robust JavaScript development. Avoid common pitfalls like redundant 
re-throws, silent failures, and overly verbose error messages. Embrace best practices by using global
error handlers, dedicated error classes, and thoughtful logging. Differentiate between expected and
unexpected errors, and leverage tools like winston for logging and Sentry for monitoring. Clean and 
consistent error handling makes your code maintainable, your debugging painless, and your user experience seamless.

``` 
