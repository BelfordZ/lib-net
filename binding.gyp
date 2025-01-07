{
  "targets": [
    {
      "target_name": "shardus-net",
      "sources": [ "native/index.node" ],
      "include_dirs": [],
      "libraries": [],
      "conditions": [
        ['OS=="win"', {
          "libraries": []
        }]
      ]
    },
    {
      "target_name": "action_after_build",
      "type": "none",
      "dependencies": [ "<(module_name)" ],
      "copies": [
        {
          "files": [ "<(PRODUCT_DIR)/<(module_name).node" ],
          "destination": "<(module_path)"
        }
      ]
    }
  ]
} 