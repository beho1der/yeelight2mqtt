package args

import (
	"flag"
)

type Arg struct {
	ConfigsDirPath *string
	CreateConfig   bool
}

func ProcessArgs() (*Arg, error) {
	arg, err := parseArgs()
	if err != nil {
		return arg, err
	}
	return arg, nil
}

func parseArgs() (*Arg, error) {
	updateHelp()

	createConfig := flag.Bool("create-config", false, "создаёт папку с шаблонами конфигов, если они не существуют")

	flag.Parse()

	arg := new(Arg)
	arg.CreateConfig = *createConfig

	// Конфиг представлен первым свободным аргументом
	nonFlag := flag.Args()
	if len(nonFlag) >= 1 {
		if nonFlag[0] != "" {
			arg.ConfigsDirPath = &nonFlag[0]
		}
	}

	return arg, nil
}

func updateHelp() {
	flag.Usage = func() {
		print(`Сервис для работы с адресным класификатором адресов

Использование: goGAR [command] [patch_to_config]  пример: ./yeelight2mqtt /etc/yeelight2mqtt/config.yaml

Команда:
	-create-config      Создаёт папку с шаблонами конфигов по пути переданному пути, если их не существует.
`)
	}
}
