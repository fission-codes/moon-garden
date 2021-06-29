// @ts-ignore
import { Elm } from './Main.elm'
import * as wn from 'webnative'

const elmApp = Elm.Main.init({
})

let state: wn.State | null = null;

wn.initialise({
    permissions: {
        app: {
            name: "Digital Garden",
            creator: "Fission"
        },
        fs: {
            public: [ wn.path.directory("Documents", "Notes") ]
        }
    }
}).then(initState => {
    console.debug("init state", initState)
    state = initState

    elmApp.ports.redirectToLobby.subscribe(() => {
        wn.redirectToLobby(state.permissions)
    })

    elmApp.ports.webnativeInit.send(state.authenticated)

}).catch(err => {
    console.error(err)
})

window["wn"] = wn
window["getState"] = () => state
