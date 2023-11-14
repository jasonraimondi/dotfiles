// Get's WAN IP from a dig to OpenDNS
export const command = "ip.widget/ip.sh";

// Refresh every X miliseconds
export const refreshFrequency = 120 * 1000;

// Base layout
export const className = {
  bottom: "10px",
  left: "10px",
  color: "#fff",
  fontFamily: "JetBrainsMonoNL Nerd Font Mono",
  fontSize: "18px",
};

// Render the widget
export const render = ({ output, error }) => {
  if (error) {
    return (
      <div>
        Oops: <strong>{String(error)}</strong>
      </div>
    );
  }

  try {
    // Collect Interfaces from JSON
    const interfaces = JSON.parse(output).interfaces;

    // Map over the interfaces and construct table contents
    const items = interfaces.map((el) => {
      return (
        <tr key={el.iface}>
          <td>
            {el.iface}: <span>{el.address}</span>
            <span style={{ color: "rgba(255,255,255,0.5)" }}>{el.cidr ? "/" + el.cidr : ""}</span>
            <span style={{ color: "rgba(255,255,255,0.5)" }}>
              {el.router ? " -> " + el.router : ""}
            </span>
          </td>
        </tr>
      );
    });

    return (
      <table>
        <tbody>{items}</tbody>
      </table>
    );
  } catch (e) {
    error = e.message;
  }

  return (
    <div>
      Oops: <strong>{String(error)}</strong>
    </div>
  );
};
