# Extraction Scripts

Platform-agnostic JavaScript snippets for extracting site data via browser automation.

## Internal Link Discovery

```javascript
JSON.stringify([...new Set(
  [...document.querySelectorAll('a[href]')]
    .map(a => {
      try { return new URL(a.href, location.origin); } catch { return null; }
    })
    .filter(u => u && u.origin === location.origin)
    .map(u => u.pathname.replace(/\/$/, '') || '/')
    .filter(p => !p.match(/\.(pdf|png|jpg|jpeg|gif|svg|webp|avif|zip|xml|json|css|js|ico|woff|woff2|ttf|eot)$/i))
    .filter(p => !p.match(/^\/(api|admin|login|auth|signin|signup|register|dashboard|account|checkout|cart)\b/i))
)].sort());
```

## Header and Footer Structure

```javascript
JSON.stringify({
  header: (() => {
    const h = document.querySelector('header') || document.querySelector('nav');
    if (!h) return null;
    return {
      tag: h.tagName,
      html: h.outerHTML.slice(0, 5000),
      links: [...h.querySelectorAll('a[href]')].map(a => ({
        text: a.textContent.trim(),
        href: new URL(a.href, location.origin).pathname,
        isExternal: new URL(a.href, location.origin).origin !== location.origin
      })),
      hasDropdowns: h.querySelectorAll('[data-dropdown], details, [aria-haspopup]').length > 0,
      hasMobileToggle: h.querySelectorAll('[aria-label*="menu"], [aria-label*="Menu"], .hamburger, .mobile-toggle, button[aria-expanded]').length > 0
    };
  })(),
  footer: (() => {
    const f = document.querySelector('footer');
    if (!f) return null;
    return {
      html: f.outerHTML.slice(0, 5000),
      linkGroups: [...f.querySelectorAll('div, section, nav')].filter(el =>
        el.querySelectorAll('a').length >= 2 && el.children.length <= 15
      ).map(group => ({
        heading: group.querySelector('h2, h3, h4, h5, p, span')?.textContent?.trim(),
        links: [...group.querySelectorAll('a')].map(a => ({
          text: a.textContent.trim(),
          href: a.href,
          isExternal: new URL(a.href, location.origin).origin !== location.origin
        }))
      }))
    };
  })()
});
```

## Per-Component CSS Extraction

```javascript
(function(selector) {
  const el = document.querySelector(selector);
  if (!el) return JSON.stringify({ error: 'Element not found: ' + selector });
  const props = [
    'fontSize','fontWeight','fontFamily','lineHeight','letterSpacing','color',
    'textTransform','textDecoration','backgroundColor','background',
    'padding','paddingTop','paddingRight','paddingBottom','paddingLeft',
    'margin','marginTop','marginRight','marginBottom','marginLeft',
    'width','height','maxWidth','minWidth','maxHeight','minHeight',
    'display','flexDirection','justifyContent','alignItems','gap',
    'gridTemplateColumns','gridTemplateRows',
    'borderRadius','border','borderTop','borderBottom','borderLeft','borderRight',
    'boxShadow','overflow','overflowX','overflowY',
    'position','top','right','bottom','left','zIndex',
    'opacity','transform','transition','cursor',
    'objectFit','objectPosition','mixBlendMode','filter','backdropFilter',
    'whiteSpace','textOverflow','WebkitLineClamp'
  ];
  function extractStyles(element) {
    const cs = getComputedStyle(element);
    const styles = {};
    props.forEach(p => { const v = cs[p]; if (v && v !== 'none' && v !== 'normal' && v !== 'auto' && v !== '0px' && v !== 'rgba(0, 0, 0, 0)') styles[p] = v; });
    return styles;
  }
  function walk(element, depth) {
    if (depth > 4) return null;
    const children = [...element.children];
    return {
      tag: element.tagName.toLowerCase(),
      classes: element.className?.toString().split(' ').slice(0, 5).join(' '),
      text: element.childNodes.length === 1 && element.childNodes[0].nodeType === 3 ? element.textContent.trim().slice(0, 200) : null,
      styles: extractStyles(element),
      images: element.tagName === 'IMG' ? { src: element.src, alt: element.alt, naturalWidth: element.naturalWidth, naturalHeight: element.naturalHeight } : null,
      childCount: children.length,
      children: children.slice(0, 20).map(c => walk(c, depth + 1)).filter(Boolean)
    };
  }
  return JSON.stringify(walk(el, 0), null, 2);
})('SELECTOR');
```

## Asset Discovery

Run on each page to discover all downloadable assets:

```javascript
JSON.stringify({
  images: [...document.querySelectorAll('img')].map(img => ({
    src: img.src || img.currentSrc,
    alt: img.alt,
    width: img.naturalWidth,
    height: img.naturalHeight,
    parentClasses: img.parentElement?.className,
    siblings: img.parentElement ? [...img.parentElement.querySelectorAll('img')].length : 0,
    position: getComputedStyle(img).position,
    zIndex: getComputedStyle(img).zIndex
  })),
  videos: [...document.querySelectorAll('video')].map(v => ({
    src: v.src || v.querySelector('source')?.src,
    poster: v.poster,
    autoplay: v.autoplay,
    loop: v.loop,
    muted: v.muted
  })),
  backgroundImages: [...document.querySelectorAll('*')].filter(el => {
    const bg = getComputedStyle(el).backgroundImage;
    return bg && bg !== 'none';
  }).map(el => ({
    url: getComputedStyle(el).backgroundImage,
    element: el.tagName + '.' + (el.className?.toString().split(' ')[0] || '')
  })),
  svgCount: document.querySelectorAll('svg').length,
  fonts: [...new Set([...document.querySelectorAll('*')].slice(0, 200).map(el => getComputedStyle(el).fontFamily))],
  favicons: [...document.querySelectorAll('link[rel*="icon"]')].map(l => ({ href: l.href, sizes: l.sizes?.toString() }))
});
```
