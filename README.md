# Phoenix Tube

Sync youtube videos with your friends online! 

![pic](https://imgur.com/hTHXGo5.png)

**NOTE:** this will only work on Chrome because of lack of lookahead assertions in other browsers. Also users need to be registered and logged in to be able to have videos in sync with one another

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Make an .env file in the root directory with `export YOUTUBE_API_KEY= "XXXXXXXX"`
  * Run `source .env` in a bash terminal
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
  
  
  # Demo (Video)
  [![Site Demo](http://img.youtube.com/vi/vjKG1eoOZTA/0.jpg)](https://youtu.be/vjKG1eoOZTA "Site Demo")
  
## Todo
- [x] Add UUIDs to Rooms 
- [x] Add the option for rooms to be public or private
- [x] Load a rooms entire playlist on join
- [x] User counts in room
- [x] User counts outside of room
- [ ] Add flash's for user actions (user switching video)
- [ ] Allow creator of a room to restrict access of switching videos 
- [ ] Allow creator of a room to BAN 🔨 people
