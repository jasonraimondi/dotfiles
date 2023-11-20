// Get's WAN IP from a dig to OpenDNS
export const command = "cat $HOME/Notebook/__DESKTOP.md";

// Refresh every X miliseconds
export const refreshFrequency = 1 * 1000;

// Base layout
export const className = {
  top: 300,
  left: 10,
  color: "#fff",
  fontFamily: "Bad Script",
  fontWeight: 800,
  fontSize: 24,
};

// Render the widget
export const render = ({ output }) => {
  const lines = output.split("\n");

  if (lines.length === 0) return null;

  return (
    <div>
      {lines.map((line, index) => (
        <div key={index}>{line}</div>
      ))}
    </div>
  );
};
