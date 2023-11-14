const displayIcon = "uptime_pro.widget/white_clock.png";

export const command =
  "uptime | awk '{ if ((/day/ && /hr/) || (/day/ && /min/) || (/day/ && /sec/)){ print $3, substr($4, 1, length($4)-1), $5, substr($6, 1, length($6)-1) } else if (/day/) { print $3, substr($4, 1, length($4)-1), substr($5, 1, length($5)-1) } else if (/sec/ || /min/ || /hr/)  { print $3, substr($4, 1, length($4)-1) } else { print substr($3, 1, length($3)-1) } }'";

export const refreshFrequency = 60 * 1000;

export const className = `
bottom: 10px;
right:  10px;
font-family: "JetBrainsMonoNL Nerd Font Mono";
color: #fff;

div {
  font-size: 18px;
  font-weight: 400;
  padding: 4px 8px 4px 6px;
}

.uptime {
  font-size: 18px;
  font-weight: 500;
  margin: 1px;
}

img {
  height: 18px;
  width: 18px;
  margin-bottom: -3px;
}
`;

export const render = ({ output }) => {
  return (
    <div>
      <img id="arrowIcon" src={displayIcon} />
      &nbsp;
      <span>
        Uptime: <a class="uptime">{output}</a>
      </span>
    </div>
  );
};
