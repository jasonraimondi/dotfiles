import { css } from "uebersicht";

export const className = `
  left: 10px;
  top: 180px;

  font-family: "FiraCode Nerd Font";
  font-size: 18px;
  color: white;
`;

const container = css`
  list-style-type: none;
  margin: 0;
  padding-left: 0;
`;

export const item = css`
  display: flex;
  justify-content: space-between;

  span:first-child {
    margin-right: 25px;
  }
`;

export const refreshFrequency = 60 * 1000;

export const command = "check-urls.widget/loop_list.sh check-urls.widget/test.list";

export const render = ({ output }) => {
  const sites = output
    .split("\n")
    .map(o => {
      const [url, online] = o.split("|");
      return {
        url,
        online,
        color: online === "online" ? "#10B981" : "#f43f5e",
      };
    })
    .filter((o) => o.url !== "");

  return (
    <ul className={container}>
      {sites.map((s) => (
        <li className={item}>
          <span>{s.url}</span>
          <span style={{ color: s.color }}>{s.online}</span>
        </li>
      ))}
    </ul>
  );
};
