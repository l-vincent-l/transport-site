import showdown from 'showdown'

<markdown>
    <div></div>

    <script type="es6">
        this.set = () => {
            this.root.childNodes[0].innerHTML = convert(this.opts.content)
        }
        this.on('update', this.set)
        this.on('mount', this.set)

        var convert = (markdown) => {
            var converter = new showdown.Converter()
            return converter.makeHtml(markdown)
        }
    </script>

</markdown>
