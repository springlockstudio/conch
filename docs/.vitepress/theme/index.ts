import { h, onMounted, onUnmounted } from "vue";
import { DividePage } from 'vitepress-theme-api';
import { Theme } from "vitepress";
import DefaultTheme, { VPButton } from "vitepress/theme";
import {  
  NolebaseHighlightTargetedHeading
} from '@nolebase/vitepress-plugin-highlight-targeted-heading/client'
import { enhanceAppWithTabs } from 'vitepress-plugin-tabs/client'
import "./style.css";
import './vars.css';
import { 
	NolebaseInlineLinkPreview,
	NolebaseInlineLinkPreviewPlugin, 
  } from '@nolebase/vitepress-plugin-inline-link-preview/client'

export default {
  extends: DefaultTheme,
  Layout: () => {
    return h(DefaultTheme.Layout, null, {
      'layout-top': () => [
        h(NolebaseHighlightTargetedHeading),
      ],
    })
  },
  enhanceApp({ app, router, siteData }) {
    // ...
	app.use(NolebaseInlineLinkPreviewPlugin);
    app.component("DividePage", DividePage);
	app.component("Button", VPButton)
	app.component("VPNolebaseInlineLinkPreview", NolebaseInlineLinkPreview)
    enhanceAppWithTabs(app);
  },
} satisfies Theme;