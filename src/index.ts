// @ts-ignore
import { Elm } from './Main.elm'
import * as wn from 'webnative'
import debounce from 'lodash/debounce'

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
            public: [wn.path.directory("Documents", "Notes")]
        }
    }
}).then(initState => {
    console.debug("Initial state", initState)
    state = initState

    elmApp.ports.redirectToLobby.subscribe(() => {
        wn.redirectToLobby(state.permissions)
    })

    elmApp.ports.persistNote.subscribe(debounce(async ({ noteName, noteData }: { noteName: string, noteData: string }) => {
        if (!state.authenticated) return
        
        console.log("persisting", noteName)

        const path = wn.path.file("public", "Documents", "Notes", `${noteName}.md`)

        await state.fs.write(path, noteData)
        await state.fs.publish()

        elmApp.ports.persistedNote.send({ noteName, noteData })

        await loadNotesLs()
    }, 1500))

    elmApp.ports.loadNote.subscribe(async (noteName: string) => {
        console.log("loadNote", state.authenticated, noteName)
        if (!state.authenticated) return

        const path = wn.path.file("public", "Documents", "Notes", `${noteName}.md`)
        elmApp.ports.loadedNote.send({
            noteName,
            noteData: new TextDecoder().decode(await state.fs.read(path) as Uint8Array)
        })
    })

    if (state.authenticated) {
        elmApp.ports.webnativeInit.send({
            username: state.username,
        })
    } else {
        elmApp.ports.webnativeInit.send(null)
    }


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
