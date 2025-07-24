// Phoenix LiveView Hooks

let Hooks = {}

Hooks.Countdown = {
    mounted() {
        let seconds = parseInt(this.el.dataset.seconds)

        const updateCountdown = () => {
            if (seconds <= 0) {
                this.el.innerHTML = '<span class="text-red-600">Time Expired</span>'
                return
            }

            const hours = Math.floor(seconds / 3600)
            const minutes = Math.floor((seconds % 3600) / 60)
            const secs = seconds % 60

            this.el.innerHTML =
                `<span class="text-2xl">${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}</span>`

            seconds--
        }

        // Initial update
        updateCountdown()

        // Update every second
        this.interval = setInterval(updateCountdown, 1000)
    },

    destroyed() {
        // Clean up interval when element is removed
        if (this.interval) {
            clearInterval(this.interval)
        }
    }
}

Hooks.NoPaste = {
    mounted() {
        this.handlePaste = (e) => {
            e.preventDefault()
            return false
        }

        this.handleContextMenu = (e) => {
            e.preventDefault()
            return false
        }

        this.el.addEventListener('paste', this.handlePaste)
        this.el.addEventListener('contextmenu', this.handleContextMenu)
    },

    destroyed() {
        this.el.removeEventListener('paste', this.handlePaste)
        this.el.removeEventListener('contextmenu', this.handleContextMenu)
    }
}

export default Hooks
