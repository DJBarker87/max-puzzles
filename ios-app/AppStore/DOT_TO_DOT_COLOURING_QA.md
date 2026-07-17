# Semantic Dot-to-Dot Colouring QA

Review target: the 84 pictures rebuilt from the `d1`–`d7` worksheets.

The colouring activity is a second, full-screen stage. It must begin only after the child's
straight dot-to-dot trail has completed its morph into the detailed source drawing. The source
drawing—not vertical bands or an arbitrary silhouette—defines every colourable region.

## Automated acceptance contract

- Every one of the 84 downloaded pictures has a semantic colour plan.
- A plan contains four or five child-meaningful colour groups with consecutive identifiers,
  distinct names, valid six-digit RGB colours, and at least one label/touch point per group.
- Every group owns a unique, in-bounds 5-by-3 atlas tile, and every referenced mask asset exists.
- Mask and label coordinates are normalised to `0...1`; no metadata can address a neighbouring
  atlas cell.
- Repeated taps or strokes in one group count once. Progress is the number of distinct groups
  attempted, never the number of touch events.
- Tap to Fill and Pencil Shading share one progress model. Changing mode preserves selected colour,
  fills, strokes, and saved progress.
- Pencil strokes store normalised points and render through the selected semantic mask. Paint must
  not appear in another region or outside the picture/canvas.
- Finish remains unavailable until all groups have either been filled or genuinely shaded.

The giraffe is the canonical semantic check: blue sky/background, golden-yellow body, warm-brown
spots/hooves/ossicones, a soft pink muzzle/inner ears, and a light detail group. A random rotated
palette or evenly sliced picture fails this check.

## Manual visual matrix

Inspect at least one picture from each topology below in both modes, on a small iPhone and iPad:

| Topology | Required examples | What to verify |
|---|---|---|
| Many disconnected islands | Giraffe spots, tiger stripes, bumblebee stripes | One semantic colour controls every intended island and nothing else. |
| Large background | Giraffe, rocket, submarine, rain cloud | Background reaches all four canvas edges without painting over the subject. |
| Holes and nested areas | Doughnut, bus windows, submarine portholes | Inner regions stay separately selectable and mask edges do not bleed. |
| Thin features | Ant legs, grasshopper legs, sailboat mast | Pencil shading is visible but remains clipped to the thin feature. |
| Overlapping details | Tropical island, hatching chick, birthday cake | Foreground line art remains crisp and above every fill/stroke. |
| Light-on-light regions | Cow, penguin, pearl shell, hot chocolate | Unpainted, white, and cream areas remain distinguishable. |

For each example:

1. Complete the last dot and confirm the straight joined line dissolves before colouring appears.
2. Confirm the colouring canvas expands to the available full screen using aspect fit, with no
   cropped source art and no coordinate drift after rotation.
3. In Tap to Fill, choose a wrong swatch and touch a region; no fill or progress should be awarded.
4. Choose the correct swatch; all components of that semantic group fill and progress advances once.
5. Switch to Pencil Shading. Draw across a boundary and outside the subject; only the portion inside
   the selected mask should remain.
6. Switch modes twice and rotate once; all work and the selected swatch must remain intact.
7. Finish every group, leave, and reopen; saved progress must be restored for the same child only.

## UX and technical risks

- **Atlas alignment:** colour masks, black line art, hit-testing, and strokes must use one identical
  aspect-fit transform. Independent padding or crop maths will visibly offset colour.
- **Atlas bleed:** linear sampling can pull pixels from an adjacent tile. Transparent gutters or a
  half-pixel-safe crop are required around every mask cell.
- **Disconnected components:** a semantic group may contain dozens of islands. Treating only one
  connected component as the region makes spots and stripes look broken.
- **Background masks:** a full-canvas background can intercept every touch. Hit-test the most
  specific foreground masks first, or explicitly place background last.
- **Pencil authenticity:** shading must retain the child's actual strokes. Automatically flooding a
  region after the first pencil mark makes the two modes functionally identical.
- **Progress exploits:** drag callbacks emit many samples. Award a group once, and require at least a
  meaningful in-mask stroke rather than a single accidental point.
- **Presentation races:** completion currently follows delayed animation. Guard against presenting
  the colouring stage twice, after dismissal, or before the Reduce Motion reveal has completed.
- **Memory pressure:** loading all mask atlases at once is unnecessary. Decode only the current
  picture's assets and release them when leaving the full-screen stage.
- **Small targets:** thin regions need generous semantic hit-testing without allowing colour to leak
  into a neighbour. Keep the rendered clip exact even if the touch target is expanded.
- **Accessibility:** mode and swatch choices need text labels and selected traits; colour alone cannot
  communicate meaning. VoiceOver should announce semantic names such as “yellow body”.
