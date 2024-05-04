# User Guide Guidelines

This document describes a set of guidelines for genereating contents for the Kubevirt User Guide. Exceptions can be made when it makes sense, but please try to follow this guide when possible.

## Content

- Follow [Kramdown Quick Reference](https://kramdown.gettalong.org/quickref.html) for syntax reference
- Split the contents in sections using the different levels of headers that Markdown offers.
  - Keep in mind that once rendered, the title you set in the Front Matter data will use `H1`, so start your sections from `H2`.
- [Code blocks](https://kramdown.gettalong.org/syntax.html#code-blocks), use them for:
  - code snippets.
  - file contents.
  - console commands.
  - ...
  - Use the proper tag to let the renderer know what type of contents you're including in the block for syntax highlighting.
- Don't include a command prompt in console commands, to simplify copy/paste.
- Consistency is important, makes it easier for the reader to follow along, for instance:
  - If you add your shell prompt to your console blocks, add it always or don't, but don't do half/half.
- Use backticks (`) when mentioning commands on your text.
- Use `emphasis/italics` for non-English words such as technologies, projects, programming language keywords.
- Bullet points are a great way to clearly express ideas through a series of short and concise messages. When using them:
  - Keep your bullets symmetrical. 1-2 lines each.
  - Avoid bullet clutter. Don’t write paragraphs in bullets.
- Use `admonitions` to highlight text such as  `note`, `info`, `warning`, `error` (Check reference at [Premonition](https://github.com/lazee/premonition), which is the plugin we use).
- Use of images:
  - Images are another great way to express information, for instance, instead of trying to describe your way around a UI, just add a snippet of the UI, readers will understand it easier and quicker.
  - Avoid large images, if you have to try to resize them, otherwise the image will be wider than the writing when your contents is rendered.
  - For galleries of pictures available externally, create a json file similar to [this example](https://github.com/kubevirt/kubevirt.github.io/pull/450/files#diff-9a59c35a6f79bc2711649c016037114a) and define them with `galleria: filename` in yaml preamble.
- Linking or HTTP references:
  - Linking externally can be problematic, some time after the publication of your contents, try linking to the repositories or directories, website's front page rather than to a page, etc.
  - For linking internally use [Jekyll's tags](https://jekyllrb.com/docs/liquid/tags/#links).
    - For blog posts
      ```markdown
      [Name of Link]({{ site.baseurl }}{% post_url 2010-07-21-name-of-post %})
      ```
    - For pages, collections, assets, etc
      ```markdown
      [Link to a document]({% link _collection/name-of-document.md %})
      [Link to a file]({% link /assets/files/doc.pdf %})
      ```

## Pages

To create a [page](https://jekyllrb.com/docs/pages/) follow these steps:

- Create the markdown file, `filename.md`, in desired directory.
- `Pages` also use [Front Matter](https://jekyllrb.com/docs/front-matter/), here's an example:

  ```yaml
  ---
  layout: default
  title: Introduction
  permalink: /docs/
  navbar_active: Docs
  ---
  ```

- The fields have the same function as for blog posts, but some values are different, as we're producing different contents.

  - **layout**: Defines style settings for different types of contents. Just use `default` as the value.
  - **title**: The title for your page.
  - **permalink** tells `Jekyll` what the output path for your page will be, it's useful for linking and web indexers.
  - **navbar_active** will add your page to the navigation bar you specify as value, commonly used values are `Docs` or `Videos`.

## Deprecating Content
Please refer to the [support matrix](https://github.com/kubevirt/sig-release/blob/main/releases/k8s-support-matrix.md). Once content is past three versions out of date (i.e. it is no longer on the matrix) it is safe to remove.