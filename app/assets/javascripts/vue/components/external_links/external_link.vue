<template lang="pug">
  .b-collection_item
    .delete(
      @click="remove(link)"
    )
    .drag-handle
    input(
      type="hidden"
      v-model="link.entry_id"
      :name="field_name('entry_id')"
    )
    input(
      type="hidden"
      v-model="link.entry_type"
      :name="field_name('entry_type')"
    )
    input(
      type="hidden"
      v-model="link.created_at"
      :name="field_name('created_at')"
    )
    input(
      type="hidden"
      v-model="link.updated_at"
      :name="field_name('updated_at')"
    )
    input(
      type="hidden"
      v-model="link.imported_at"
      :name="field_name('imported_at')"
    )
    input(
      type="hidden"
      v-model="link.source"
      :name="field_name('source')"
    )
    .b-input.select
      select(
        v-model="link.kind"
        :name="field_name('kind')"
      )
        option(
          v-for="kind_option in kind_options"
          :value="kind_option.last()"
        ) {{ kind_option.first() }}
    .b-input
      input(
        type="text"
        v-model="link.url"
        :name="field_name('url')"
        :placeholder="I18n.t('activerecord.attributes.external_link.url')"
        @keydown.enter="submit"
        @keydown.8="remove_empty(link)"
        @keydown.esc="remove_empty(link)"
      )
</template>

<script>
import { mapGetters, mapActions } from 'vuex'

export default {
  props: {
    link: Object,
    kind_options: Array,
    resource_type: String,
    entry_type: String,
    entry_id: Number
  },
  computed: {
    ...mapGetters([
    ]),
  },
  methods: {
    field_name(name) {
      if (!Object.isEmpty(this.link.url)) {
        return `${this.resource_type.toLowerCase()}[external_links][][${name}]`
      } else {
        return ''
      }
    },
    submit(e) {
      if (!e.metaKey && !e.ctrlKey) {
        e.preventDefault()
        this.$emit('add_next')
      }
    },
    remove_empty(link) {
      if (Object.isEmpty(link.url) && this.$store.state.collection.length > 1) {
        this.remove(link)
        this.$emit('focus_last')
      }
    },
    ...mapActions([
      'remove'
    ])
  },
  mounted() {
    this.$nextTick(() => {
      $('input', this.$el).focus()
    })
  }
}
</script>

<style scoped lang="sass">
  .b-collection_item
    &:first-child:last-child
      .drag-handle
        display: none

    .b-input
      margin-bottom: 2px

      &.select
      margin-bottom: 5px

      input
        width: 100%
</style>
