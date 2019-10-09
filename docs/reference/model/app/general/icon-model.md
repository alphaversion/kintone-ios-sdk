# Icon
The Icom of an apps.

## Constructor

### **Parameter**


| Name| Type| Description |
| --- | --- | --- |
| key | String | The key of the Icon
| iconType | [IconType](#icontype) | The icon type of the Icon
| file | [FileModel](/reference/model/file/file-model) | The file of the Icon

## Methods

### getFile

The file of the Icon

**Declaration**

```
func getFile() -> FileModel?
```

**Parameter**

(none)

**Return**

[FileModel](/reference/model/file/file-model)

### getKey

The key of the Icon

**Declaration**

```
func getKey() -> String?
```

**Parameter**

(none)

**Return**

String

### getIconType

The icon type of the Icon

**Declaration**

```
func getIconType() -> IconType?
```

**Parameter**

(none)

**Return**

[IconType](#icontype)

## Enum

### IconType

| Name | Type | Value 
| --- | --- | --- |
| FILE | String | FILE 
| PRESET | String | PRESET