exports.config =
  files:
    javascripts:
      joinTo:
        'scripts/vendor.js': /^(bower_components|vendor)/
        'scripts/app.js': /^app/
      order:
        before: ['bower_components/jquery/dist/jquery.js']

    stylesheets:
      joinTo:
        'styles/app.css': /^app/
        'styles/vendor.css': /^(bower_components|vendor)/

    templates:
      joinTo: 'app.js'

 server:
    path: 'public/'
    port: 3333
    base: '/'
    run: yes
