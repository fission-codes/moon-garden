// @ts-ignore
import { Elm } from './Main.elm'
import * as wn from 'webnative'

const elmApp = Elm.Main.init({
})

let state: wn.State | null = null;

wn.initialise({
    permissions: {
        app: {
            name: "Moon Garden",
            creator: "Fission"
        },
        fs: {
            public: [ wn.path.directory("Documents", "Notes") ]
        }
    }
}).then((initState: wn.AuthSucceeded) => {
    console.debug("Initial state", initState)
    state = initState
    const {fs} = state

    elmApp.ports.redirectToLobby.subscribe(() => {
        wn.redirectToLobby(state.permissions)
    })

    elmApp.ports.webnativeInit.send(state.authenticated)

    elmApp.ports.persistNote.subscribe(({noteName, noteData}) => {
        const path = wn.path.file("public", "Documents", "Notes", `${noteName}.md`)

        fs.write(path, noteData).then(() => {
            console.debug("Content: ", noteData)
            console.debug("Wrote note to ", path)
            fs.publish().then(() => {
                console.debug("Published")
            })
        })
    })
}).catch(err => {
    console.error(err)
})

window["wn"] = wn
window["elmApp"] = elmApp
window["getState"] = () => state
