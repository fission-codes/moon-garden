// @ts-ignore
import { Elm } from './Main.elm'
import * as wn from 'webnative'

const elmApp = Elm.Main.init({
    flags: {
        randomness: crypto.getRandomValues(new Int32Array(1))[0]
    }
})

let state: wn.State | null = null;

wn.setup.debug({ enabled: true })

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
}).then(initState => {
    console.debug("Initial state", initState)
    state = initState

    elmApp.ports.redirectToLobby.subscribe(() => {
        wn.redirectToLobby(state.permissions)
    })

    elmApp.ports.webnativeInit.send(state.authenticated)

    elmApp.ports.persistNote.subscribe(({noteName, noteData}) => {
        const path = wn.path.file("public", "Documents", "Notes", `${noteName}.md`)

        if (state.authenticated) {
            const fs = state.fs

            fs.write(path, noteData).then(() => {
                console.debug("Content: ", noteData)
                console.debug("Wrote note to ", path)
                fs.publish().then(() => {
                    console.debug("Published")
                    loadNotesLs()
                })
            })
        }
    })

    loadNotesLs()
}).catch(err => {
    console.error(err)
})

window["wn"] = wn
window["elmApp"] = elmApp
window["getState"] = () => state


async function loadNotesLs() {
    if (!state.authenticated) return
    const dir = wn.path.directory("public", "Documents", "Notes")
    const entries = await state.fs.ls(dir)
    let entriesWithMetadata = {}
    for (const [key, entry] of Object.entries(entries)) {
        const path = wn.path.combine(dir, entry.isFile ? wn.path.file(entry.name) : wn.path.directory(entry.name))
        const entr = await state.fs.get(path)
        entriesWithMetadata[key] = {
            ...entry,
            // @ts-ignore
            metadata: entr.header.metadata
        }
    }
    elmApp.ports.loadedNotesLs.send(entriesWithMetadata)
}
