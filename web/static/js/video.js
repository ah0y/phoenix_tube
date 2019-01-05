import Player from './player'
import {Presence, Socket} from "phoenix"


let Video = {

    init(element) {
        if (!element) {
            return
        }
        let playerId = element.getAttribute("data-player-id");
        let videoId = element.getAttribute("data-id");
        let socket = new Socket("/socket", {
            params: {token: window.userToken},
            // logger: (kind, msg, data) => {console.log(`${kind} : ${msg}`, data) }
        })
        socket.connect();
        Player.init(element.id, playerId, () => {
            this.onReady(videoId, socket)
        })
    },

    onReady(videoId, socket) {
        let msgContainer = document.getElementById("msg-container");
        let playlistContainer = document.getElementById("playlist-container");
        let msgInput = document.getElementById("msg-input");
        let usersButton = document.getElementById("users");
        let chatButton = document.getElementById("chat");
        let userView = document.getElementById("user-view");
        let chatView = document.getElementById("chat-view");
        let usersContainer = document.getElementById("users-container");
        let vidChannel = socket.channel("rooms:" + videoId);
        let newVideo = document.getElementById("playlist-input");
        let presences = {};
        let listBy = (user, {metas: metas}) => {
            return {
                username: metas[0].username[0]
                // onlineAt: metas
            }
        };

        let renderUsers = (presences) => {
            console.log(Object.keys(presences).length)
            usersContainer.innerHTML = Presence.list(presences, listBy)
                .map(presences=> `
        <p>
		    <b>${presences.username}</b>
        </p>
        `).join("");
            var online = Object.keys(presences).length
            usersButton.innerHTML = online
            // vidChannel.push("users_count", {} )
        };

        Player.onPlayerStateChange = function (event) {
            switch (event.data) {
                case YT.PlayerState.UNSTARTED:
                    console.log('unstarted');
                    break;
                case YT.PlayerState.ENDED:
                    console.log('ended');
                    break;
                case YT.PlayerState.PLAYING:
                    console.log('playing');
                    vidChannel.push("playing", {time: this.getCurrentTime()});
                    break;
                case YT.PlayerState.PAUSED:
                    vidChannel.push("paused", {time: this.getCurrentTime()});
                    console.log('paused');
                    break;
                case YT.PlayerState.BUFFERING:
                    console.log('buffering');
                    break;
                case YT.PlayerState.CUED:
                    console.log('video cued');
                    break;
            }
        },

            newVideo.addEventListener("keydown", (e) => {
                if (e.keyCode == 13) {
                    vidChannel.push("new_video", {url: newVideo.value})
                    newVideo.value = ""
                }
            }),

            vidChannel.on("new_video", (resp => {
                this.renderPlaylist(playlistContainer, resp)
            })),

            vidChannel.on("play_video", (resp => {
                let patt = new RegExp(/(youtube.com|youtu.be)\/(watch)?(\?v=)?(\S+)?/);
                let id = new RegExp(/^.*(?:youtu\.be\/|\w+\/|v=)([^#&?]*)/);
                if (patt.test(resp.url)) {
                    Player.player.loadVideoById(id.exec(resp.url)[1], 0, "large");
                }
                else {
                    console.log("not a valid youtube link")
                }
            })),

            vidChannel.on("playing", (resp => {
                if (Math.abs(Player.getCurrentTime() - resp.time) > 200) {
                    Player.seekTo(Math.max(resp.time, Player.getCurrentTime()))
                }
                else {
                    Player.player.playVideo()
                }
            })),

            vidChannel.on("presence_state", (state => {
                console.log("state")
                presences = Presence.syncState(presences, state);
                renderUsers(presences)
            })),

            vidChannel.on("presence_diff", (diff => {
                console.log("diff")
                vidChannel.push("users_count", {} )
                presences = Presence.syncDiff(presences, diff)
                renderUsers(presences)
            })),

            vidChannel.on("paused", (resp) => {
                Player.seekTo(resp.time);
                Player.player.pauseVideo()
            }),

            vidChannel.on("new_annotation", (resp) => {
                vidChannel.params.last_seen_id = resp.id;
                console.log(resp)
                this.renderAnnotation(msgContainer, resp)
            }),

            playlistContainer.addEventListener("click", e => {
                if (e.path[0].getAttribute("class") == "playlist-item") {
                    vidChannel.push("play_video", {url: e.path[0].getAttribute("link")})
                }
            }),

            chatButton.addEventListener("click", e => {
                userView.style.display = "none"
                chatView.style.display = "block";
            }),

            usersButton.addEventListener("click", e => {
                chatView.style.display = "none";
                userView.style.display = "block"

            }),

            msgInput.addEventListener("keydown", e => {
                if (e.keyCode == 13) {
                    let payload = {body: msgInput.value, at: Player.getCurrentTime()};
                    vidChannel.push("new_annotation", payload)
                    msgInput.value = ""
                }
            })

        msgContainer.addEventListener("click", e => {
            e.preventDefault();
            let seconds = e.target.getAttribute("data-seek") ||
                e.target.parentNode.getAttribute("data-seek");
            if (!seconds) {
                return
            }
            Player.seekTo(seconds)
        }),

            vidChannel.join()
                .receive("ok", resp => {
                    let ids = resp.annotations.map(ann => ann.id);
                    if (ids.length > 0) {
                        vidChannel.params.last_seen_id = Math.max(...ids)
                    }
                    this.schedulePlaylist(playlistContainer, resp.playlist)
                    this.scheduleMessages(msgContainer, resp.annotations)
                })
                .receive("error", reason => console.log("join failed", reason))
    },

    renderAnnotation(msgContainer, {user, body, at}){
        let template = document.createElement("div");
        template.innerHTML = `
		<p>
		    <b>${this.esc(user.username)}</b>: ${this.esc(body)}
        </p>
		`;
        msgContainer.appendChild(template);
        msgContainer.scrollTop = msgContainer.scrollHeight
    },

    renderPlaylist(playlistContainer, {title, url}){
        let template = document.createElement("div");
        template.innerHTML = `
		<a  class="playlist-item" link="${url}"> ${title}
		</a>
		`;
        playlistContainer.appendChild(template);
        playlistContainer.scrollTop = playlistContainer.scrollHeight
    },

    esc(str){
        let div = document.createElement("div");
        div.appendChild(document.createTextNode(str));
        return div.innerHTML
    },

    scheduleMessages(msgContainer, annotations){
        setTimeout(() => {
            let ctime = Player.getCurrentTime();
            let remaining = this.renderAtTime(annotations, ctime, msgContainer);
            this.scheduleMessages(msgContainer, remaining)
        }, 1000)
    },

    schedulePlaylist(playlistContainer, playlist) {
        setTimeout(() => {
            let remaining = this.renderPlaylistItems(playlist, 0, playlistContainer);
            this.schedulePlaylist(playlistContainer, remaining)
        })
    },

    renderPlaylistItems(playlist, seconds, playlistContainer){
        return playlist.filter(video => {
            this.renderPlaylist(playlistContainer, video);
            return false

        })
    },

    renderAtTime(annotations, seconds, msgContainer){
        return annotations.filter(ann => {
            this.renderAnnotation(msgContainer, ann);
            return false

        })
    }
};

export default Video
