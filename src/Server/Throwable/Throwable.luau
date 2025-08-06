local Throwable = {}

export type Throwable = {
    uid: string,
    position: Vector3,
    direction: Vector3,
    velocity: Vector3,
    typeName : string,
}

return Throwable