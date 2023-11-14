import { css } from "uebersicht";

export const className = `
  left: 10px;
  top: 130px;

  font-family: "Futura";
  font-size: 36px;
  color: white;
`;

const container = css`
  list-style-type: none;
  margin: 0;
  padding-left: 0;
`;

export const refreshFrequency = 120 * 1000;

export const render = () => {
  const date = new Date();
  const formatted = new Intl.DateTimeFormat("en-US", {
    month: "long",
    day: "2-digit",
    year: "numeric",
  }).format(date);
  return <p className={container}>{formatted}</p>;
};
