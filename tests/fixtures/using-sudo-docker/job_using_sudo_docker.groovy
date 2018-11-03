job('test-sudo-docker') {
    steps {
        shell('''
            set +x

            sudo docker version || KO=1
            
            if [ "$KO" -eq "1" ]; then
                echo -e "\\n\\ndocker is not available, see https://goo.gl/RpkBZz\\n\\n"
                exit 1
            else
                echo -e"\\n\\ndocker is available\\n\\n"
                sudo docker images
            fi
        '''.stripIndent())
    }
}