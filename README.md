Argós
=======

A proxy that makes purposely slows down the request.

## Todo Items

### Configurable response time
Provide a time option in url schema, something like this.
```
http://server/3/google.com
```
Where the number signifies how many seconds (or milliseconds) the request should
take.

### Better Home Page
Also use HAML and Markdown to make the home page not look like shit.

### Support Proxy Headers
Headers that argos should support:
```
X-Forwarded-For
X-Forwarded-Proto
X-Forwarded-Port
Via
```

### Modularize the Code
It's all in one file and it looks disgusting right now.

### Include Instructions for Use
Both in this README and in the index.html file.
