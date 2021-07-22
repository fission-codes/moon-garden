import typography from "@tailwindcss/typography"

export default {
  purge: [],
  darkMode: false, // or 'media' or 'class'
  theme: {
    fontFamily: {
      title: 'Lora, serif',
      body: 'Karla, sans-serif',
      button: 'Nunito VF Beta, sans-serif',
      mono: 'Courier Prime, monospace',
    },
    extend: {
      fontSize: {
        '4.5xl': '2.5rem',
      },
      colors: {
        bluegray: {
          '800': '#45465A',
          '700': '#666784',
          '600': '#5E74A6',
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
        },
        rose: {
          '300': '#D6ADE2',
          '600': '#9467A1',
        }
      },
      typography: (theme) => ({
        DEFAULT: {
          css: {
            color: theme('colors.bluegray.800'),
            maxWidth: null,
            fontFamily: theme('fontFamily.body'),
            a: {
              color: theme('colors.bluegray.600'),
              textDecoration: 'none',
              '&:hover': {
                textDecoration: 'underline',
              },
            },
            'ul > li::before': {
              backgroundColor: theme('colors.beige.400'),
            },
            strong: {
              color: theme('colors.bluegray.600'),
              fontWeight: '800',
            },
            hr: {
              borderColor: theme('colors.beige.400'),
            },
            blockquote: {
              color: theme('colors.bluegray.700'),
              borderLeftColor: theme('colors.beige.400'),
            },
            'h1, h2, h3, h4': {
              color: theme('colors.bluegray.700'),
              fontFamily: theme('fontFamily.title'),
              fontWeight: '400',
            },
            'figure figcaption': {
              color: theme('colors.bluegray.600'),
            },
            code: {
              color: theme('colors.bluegray.800'),
              fontFamily: theme('fontFamily.mono'),
            },
            'a code': {
              color: theme('colors.bluegray.600'),
            },
            thead: {
              color: theme('colors.bluegray.800'),
              borderBottomColor: theme('colors.beige.400'),
            },
            'tbody tr': {
              borderBottomColor: theme('colors.beige.400'),
            },
          },
        },
      }),
    },
  },
  variants: [],
  plugins: [
    typography,
  ],
}
