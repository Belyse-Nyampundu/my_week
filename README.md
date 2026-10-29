# My Week

Your week of classes in one Flutter app. The courses are asked from a server with `Future`, `async`, and `await`. Each day stays in order of start time, the hours add up, and two courses that overlap turn red and name each other. After the week has loaded once, your adds, edits, and deletes are saved on the phone.

## What you should see

The first open shows a spinner, then the week from the server.

- **This week · 10h 30m** at the top.
- **Monday · 3h 30m**: Mobile Programming 08:00–10:00 and Databases 10:00–11:30. They touch at 10:00, so neither card is red.
- **Tuesday**: Physics 09:00–11:00 and Mathematics 10:00–12:00 are both red. One says Clashes with Mathematics, the other Clashes with Physics. Clashes this week lists the same pair.
- **Thursday**: English and Chemistry, with Free: 14:30–16:00 between them.
- **Wednesday** and **Friday**: No classes on Wednesday, or Friday.
- With no internet the first time, you get a message and Retry. Retry works once you are back online.
- Add a course with an early start and it slots into order, not the bottom. Tap a course to edit it. Delete asks Are you sure?
- 8h, 25:00, 10:75, and an end time that is not after the start are refused with a message.
- Add, edit, or delete a course, stop the app, and run it again. All three changes are still there.

Stop the app and press Run after adding a package. Hot reload cannot add `http` or `shared_preferences`.

## Think

### Clash condition

Two courses clash when they are on the same day and each one starts before the other ends: `startA < endB` and `startB < endA`.

Why `<` and not `<=`? A course that ends at 11:00 and a course that starts at 11:00 only meet at the boundary. They do not overlap, so they are not a clash. `<=` would count that shared minute as an overlap, and back-to-back classes would turn red. `<` leaves them as normal courses.

### Why minutes

A time like 08:30 is awkward as text. You cannot subtract two strings to get a duration, and sorting text does not follow the clock: `"9:00"` comes after `"10:00"` because the character `9` comes after `1`. Stored as minutes from midnight, 08:30 is 510 and 10:00 is 600. Comparing, sorting, and adding hours is ordinary arithmetic. The screen turns the number back into `08:00` only when a person needs to read it.

### Waiting for the courses

`fetchCourses` is `async` and returns a `Future`. The screen `await`s `http.get`. Meanwhile the spinner keeps moving and the app still takes taps. If the request blocked the UI thread until the server answered, the app would freeze for the whole wait. On a slow connection that freeze would last longer.

### Saved on this phone only

`shared_preferences` keeps the courses on this phone after the first successful load. Change phone, or install the app on a second phone, and that phone asks the server again. A server tied to an account would keep every later edit for every phone.
