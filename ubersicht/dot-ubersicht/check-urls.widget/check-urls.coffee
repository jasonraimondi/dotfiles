style: """
	color: white
	left: 5px
	bottom: 100px
	font-size: 18px
	font-family: "Fira Code"
	border-radius: 6px
	border: 0px solid #222

	table
		margin: 0 auto
		td
			padding: 4px

	.ip
		opacity: 0.6
		font-size: 13px

	.url
		padding: 0 10px

	.online
		padding: 0 10px
		color: #48bb78

	.offline
		padding: 0 10px
		color: #f56565

"""

command: "check-urls.widget/loop_list.sh check-urls.widget/test.list"

refreshFrequency: 30000

render: -> """
	<div>
  	<table></table>
	</div>
"""

update: (output, domEl) ->
	urls 	= output.split("\n")
	table = $(domEl).find('table')

	table.html('')

	renderUrl = (name, status) -> """
		<tr class="row">
			<td class="url">#{ name }</td>
			<td class="#{ status }">#{ status }</td>
		</tr>
	"""

	for line in urls
		[url, status] = line.split('|')
		if url.length > 0
			table.append renderUrl(url, status)
