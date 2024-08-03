![](media/logo.png)

[![GitHub release (latest by date)](https://img.shields.io/github/v/tag/insality/detiled?style=for-the-badge&label=Release)](https://github.com/Insality/detiled/tags)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/insality/detiled/ci_workflow.yml?style=for-the-badge)](https://github.com/Insality/detiled/actions)
[![codecov](https://img.shields.io/codecov/c/github/Insality/detiled?style=for-the-badge)](https://codecov.io/gh/Insality/detiled)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)


# Disclaimer

The library in development stage. May be not fully tested and README may be not full. If you have any questions, please, create an issue.

# Detiled

**Detiled** - is a Defold library that allows you to export tilesets and maps from [Tiled](https://www.mapeditor.org/) editor to [Decore](https://github.com/Insality/decore) entities and world collections.

## Features

- **Export Tilesets** - Export tilesets from Tiled as Decore entities collection
- **Export Map** - Export map from Tiled as Decore world collection
- **Custom Properties** - Support various custom properties for tilesets and map


### [Dependency](https://www.defold.com/manuals/libraries/)

Open your `game.project` file and add the following line to the dependencies field under the project section:

**[Decore](https://github.com/Insality/decore)**

```
https://github.com/Insality/decore/archive/refs/tags/1.zip
```

**[Detiled](https://github.com/Insality/detiled/archive/refs/tags/1.zip)**

```
https://github.com/Insality/detiled/archive/refs/tags/1.zip
```

After that, select `Project ▸ Fetch Libraries` to update [library dependencies]((https://defold.com/manuals/libraries/#setting-up-library-dependencies)). This happens automatically whenever you open a project so you will only need to do this if the dependencies change without re-opening the project.

### Library Size

> **Note:** The library size is calculated based on the build report per platform

| Platform         | Library Size |
| ---------------- | ------------ |
| HTML5            | **1.96 KB**  |
| Desktop / Mobile | **3.35 KB**  |


## Setup


## Game Example

Look at [Shooting Circles](https://github.com/Insality/shooting_circles) game example to see how to use the Decore library in a real game project.


## API Reference

### Quick API Reference

```lua
detiled.set_logger(logger_instance)
detiled.get_entities_packs_data(tilesets_path)
detiled.get_worlds_packs_data(maps_list_path)
```

### API Reference

Read the [API Reference](API_REFERENCE.md) file to see the full API documentation for the module.


## Use Cases

Read the [Use Cases](USE_CASES.md) file to see several examples of how to use the this module in your Defold game development projects.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Issues and Suggestions

For any issues, questions, or suggestions, please [create an issue](https://github.com/Insality/detiled/issues).

## 👏 Contributors

<a href="https://github.com/Insality/detiled/graphs/contributors">
  <img src="https://contributors-img.web.app/image?repo=insality/detiled"/>
</a>

## ❤️ Support project ❤️

Your donation helps me stay engaged in creating valuable projects for **Defold**. If you appreciate what I'm doing, please consider supporting me!

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)

