# Created July 2018 by Mike Pennella (github.com/mpen01/uptime_pro)
#	Updated August 2022 by Jason Raimondi (github.com/jasonraimondi/dotfiles)

labelColor	  = '#fff' 
nameColor		  = '#fff'
uptimeColor	  = '#fff'
lineColor		  = 'none'
bkground		  = 'transparent'
opacityLevel	= '1'
displayIcon		= "uptime_pro.widget/white_clock.png"

command: "uptime | awk '{ if ((/day/ && /hr/) || (/day/ && /min/) || (/day/ && /sec/)){ print $3, substr($4, 1, length($4)-1), $5, substr($6, 1, length($6)-1) } 
						  else if (/day/) { print $3, substr($4, 1, length($4)-1), substr($5, 1, length($5)-1) }
						  else if (/sec/ || /min/ || /hr/)  { print $3, substr($4, 1, length($4)-1) }
						  else { print substr($3, 1, length($3)-1) } }' && scutil --get ComputerName"

# Update uptime every 60 secs
refreshFrequency: 60000

style: """
  bottom:	10px
  right:	10px
  font-family: Fira Code
  color: #{uptimeColor}

  div
    display: block
    border: 1px solid #{lineColor}
    border-radius 5px
    text-shadow: 0 0 1px #{bkground}
    background: #{bkground}
    font-size: 18px
    font-weight: 400
    opacity: #{opacityLevel}
    padding: 4px 8px 4px 6px
   
  .uptime
    font-size: 18px
    font-weight: 500
    color: #{uptimeColor}
    margin: 1px
      
  img
    height: 18px
    width: 18px
    margin-bottom: -3px
    
    
"""

render: -> """
  <div><img id="arrowIcon" src=""> Uptime: <a class='uptime'></a></div>
"""

update: (output,domEl) ->
  values		= output.split("\n")
  uptime 		= values[0]
  computername 	= values[1]
  div			= $(domEl)

  if (uptime != '')
    div.find('.uptime').html(uptime)
    div.find('.computername').html(computername)
  else
    div.find('.computername').html('Uptime is not available')
  		 
  document.getElementById("arrowIcon").src=displayIcon