package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

var certbotCmd string = "sudo certbot certonly --noninteractive --agree-tos " +
	"--cert-name boltorg -d hrtsfld.xyz -d walboard.xyz -d tagmachine.xy" +
	"z -d btstrmr.xyz -d bolt-marketing.org -d statui.hrtsfld.xyz -d mys" +
	"terygift.org -m johnathanhartsfield@gmail.com --standalone"

var copyCerts string = "sudo cp /etc/letsencrypt/live/boltorg/privkey.pem /etc/letsencrypt/live/boltorg/fullchain.pem tlsCerts/"

var forwardPort80to8080 string = "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"
var forwardPort443to8443 string = "sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443"

func main() {
	fmt.Println("Root Privileges Required...")

	// forward ports
	fmt.Println(localCommand(strings.Split(forwardPort443to8443, " ")))
	fmt.Println(localCommand(strings.Split(forwardPort80to8080, " ")))

	// get TSL certs
	if len(os.Args) > 1 {
		if os.Args[1] == "recert" {
			fmt.Println(localCommand(strings.Split(certbotCmd, " ")))
			fmt.Println(localCommand(strings.Split(copyCerts, " ")))
		}
	}
	startServices()
}

func localCommand(command []string) string {
	cmd := exec.Command(command[0], command[1:]...)
	o, err := cmd.CombinedOutput()
	if err != nil {
		log.Println("local command error: ", err, string(o))
	}
	return string(o)
}

func startServices() {
	dirs, err := os.ReadDir("/home/john/live")
	if err != nil {
		log.Println(err)
	}
	for _, dir := range dirs {
		b, err := os.ReadFile(dir.Name() + "/bolt.conf.local")
		if err != nil {
			log.Println(err)
		}
		s := string(b)
		com := strings.SplitAfter(s, "command\": \"")[1]
		fmt.Println(strings.Split("go build -o "+com, " "))
	}
}
