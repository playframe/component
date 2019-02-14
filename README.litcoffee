
![PlayFrame](https://avatars3.githubusercontent.com/u/47147479)
# Component

###### 0.3 kB Pure Stateful Styled Components

## Installation
```sh
npm install --save @playframe/component
```

## Description
Pure Functional Styled Web Components for
[PlayFrame](https://github.com/playframe/playframe). Components are
rendered independetly from the rest of the app. By using
[Shadow DOM](https://developers.google.com/web/fundamentals/web-components/shadowdom)
provided by
[ShaDOM](https://github.com/playframe/shadom)
we achieve scoped styling and simple css selectors.
Please consider using
[CSS Variables](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_variables)
for maximum animation performance and flexibility.

You can create instances manually and keep them in parent state or
you can register them with `fp.use` or `h.use` and create them dynamically.
To be able to identify the same dynamic component we use a unique
object `mkey` as a
[WeakMap](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap)
key. For a `UserView` Component actual `user` object would be a perfect
WeakMap key

## Usage
```js
import h from '@playframe/h'
import oversync from '@playframe/oversync'
import component from '@playframe/component'

const sync = oversync(Date.now, requestAnimationFrame)
const Component = component(sync)

export default myCounter = (Component)=>
  Component({
    seconds: 0,
    _: {
      reset: ()=> {seconds: 0}
      increment: (x, state)=> {
        state.seconds++
        setTimeout( state._.increment,
          (1000 - Date.now() % 1000) || 1000 )
      }
    }
  })((state)=>
    <my-counter style={ {'--border': state.border} }>
      <style>{`
        :host {
          display: block;
          border: var(--border, 0);
        }
      `}</style>
      <div>
        {props.children}
        <br/>
        {state.seconds} seconds passed
        <br/>
        <button onclick={state._.reset}> Reset </button>
      </div>
    </my-counter>
  )

// our Counter instance with initial props
const MyCounter = myCounter(Component)({seconds: 42})

// reset in 10 seconds
setTimeout(MyCounter._.reset, 10000)

const view = ()=>
  <MyCounter border="1px solid grey">
    <h1>Hello</h1>
  </MyCounter>

// or we can register component as custom element
h.use({'my-counter': (props)=>
  let mkey = props && props.mkey
  makeMyCounter(Component)({mkey})(props)
})

// mkey is used as WeakMap key to cache our statefull component
const mkey = {uniqueObject: true}

const view = ()=>
  <my-counter mkey={mkey} border="1px solid grey">Hello</my-counter>

```

## Annotated Source

We are going to use [statue](https://github.com/playframe/statue)
for managing state of our Component

    evolve = require '@playframe/evolve'
    statue = require '@playframe/statue'

How about using a tree of
[WeakMap](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WeakMap)
instances to cache our Component instances by `mkey`?
This allows us to cache our components aggresively because our `_cache`
will be cleaned automatically by Garbage Collector if `s_a`, `view` or
`mkey` gets dereferenced

    _cache = new WeakMap

    get = (s_a, view, mkey)=>
      (by_actions = _cache.get s_a) or _cache.set s_a, by_actions = new WeakMap
      (by_view = by_actions.get view) or by_actions.set view, by_view = new WeakMap
      by_view.get mkey

    set = (s_a, view, mkey, Component)=>
      _cache
        .get s_a
        .get view
        .set mkey, Component

Let's export a higher order function that takes `sync` engine,
`state_actions` for statue and a pure `view` function.

    module.exports = (sync)=>(state_actions)=>(view)=>(upgrade)=>
      if (mkey = upgrade and upgrade.mkey) and
          Component = get view, state_actions, mkey
        return Component

      _v_root = null
      _v_dom = null
      _props = null
      _scheduled = false
      _rendering = false
      _state = evolve state_actions, upgrade

Creating a statue that will deliver the latest state on
`sync.finally` and will schedule render

      update = (f)=>
        if _rendering
          f()
        else
          sync.finally f


      _state = statue _state, update, (state)=>
        _state = state
        unless _rendering or _scheduled
          _scheduled = true
          sync.render patch_shadow
        return


      render_with = (props)=>
        _rendering = true
        if props
          _state = _state._(_props = props)

        patch_shadow()
        _rendering = false
        return

`patch_shadow` is responsible for producing new virtual DOM and using
`patch` method for shadow DOM mutation provided by
[ShaDOM](https://github.com/playframe/shadom).
Please make noted that we are cleaning and keeping `_v_root` node
for fast equality pass when ShaDOM is mutating parent scrope of DOM.
This makes our components rerendered only if something changes in their
own state

      patch_shadow = =>
        _scheduled = false

        new_v_dom = view _state

        unless _v_root # first run
          _v_root = new_v_dom
          attr = _v_root[1] or= {}
          attr.attachShadow or= mode: 'open'
          attr.key or= Math.random()
        else
          unless _v_dom # second run
            _v_dom = _v_root
          else # third run
            # freeing obsolete children
            _v_root.length = 2

          _v_root.patch new_v_dom, _v_dom
          _v_dom = new_v_dom

        return

Here we create our `Component` function that mimics your `view`
function. But first it's checking if `props` are meant to update
components inner `_state`

      Component = (props)=>
        if _v_root
          unless props is _props
            # shallow equality check
            for k, v of props when v isnt _state[k]
              # updating state with props and rendering
              render_with props
              break

        else # first run
          # will create _v_root
          render_with props

        # always returning the same _v_root reference
        # this will skip rerender with the rest of the app
        _v_root

Assigning high level methods from statue, adding instance to cache and our
fresh `Component` is ready!

      Component._ = _state._

      set view, state_actions, mkey, Component if mkey


      Component
