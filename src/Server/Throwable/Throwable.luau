local Throwable = {}

export type Throwable = {
    uid: string,
    position: Vector3,
    direction: Vector3,
    velocity: Vector3,
    typeName : string,
    owner : Player,
    active : boolean
}

return Throwable