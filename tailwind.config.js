export default {
  purge: [],
  darkMode: false, // or 'media' or 'class'
  theme: {
    fontFamily: {
      title: ['Lora', 'serif'],
      body: ['Karla', 'sans-serif'],
      button: ['Nunito VF Beta', 'sans-serif'],
      mono: ['Courier Prime', 'monospace'],
    },
    extend: {
      colors: {
        bluegray: {
          '800': '#45465A',
          '700': '#666784',
        },
        beige: {
          '100': '#F4ECE1',
          '200': '#EFE2D2',
          '300': '#DBD4BC',
          '400': '#C6AE9D',
        },
        leaf: {
          '600': '#B4BC8D',
          '800': '#95A25C',
        },
        moon: {
          '200': '#D0CEF5',
        }
      },
    },
  },
  variants: [],
  plugins: [],
}
