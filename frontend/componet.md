Task: Create a React component using Tailwind CSS and Framer Motion for a "Smart Transcript" with manual annotations.

Requirements:

Data Model: The text is an array of objects: { id, text, type: 'default' | 'chip' | 'strike', color?, label? }.

Layout: > - A central container with a fixed max-width (e.g., 500px).

Text must have line-height generous enough to accommodate chips.

Manual Labels: If an object has a label property, render a small badge with a curved SVG arrow pointing to that specific word. These labels must sit in the margins (absolute positioned) so they don't push the text around.

Styles:

Chips: Solid background (purple, green, blue), white text, rounded corners.

Strike: Text turns gray #666, gets a line-through, and after a delay, the component should animate its width to 0 and opacity to 0 to "remove" it from the flow.

Animation: The whole container moves upwards slowly. Use animate={{ y: [0, -1000] }} or a similar scroll effect.

Interactive Feature: I want to be able to manually tag any word in my JSON data with a label: "My Custom Text" and have the UI automatically render the arrow and badge to the left or right of that line.