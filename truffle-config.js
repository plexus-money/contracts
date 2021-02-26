const truffleTeamsUrl = "https://sandbox.truffleteams.com/4c1224c1-3a9c-43ad-9f1e-0eecb9e8995b"

export const networks = {
  teams: {
    url: truffleTeamsUrl,
    network_id: 1,
  },
};
export const mocha = {
   timeout: 100000
};
export const compilers = {
  solc: {
    version: '0.7.4',
  }
};