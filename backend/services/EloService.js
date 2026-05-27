const { ELO } = require('../config/constants');

class EloService {
  static calculate(ratingA, ratingB, scoreA) {
    const kA = ELO.K_FACTOR;
    const kB = ELO.K_FACTOR;

    const expectedA = 1 / (1 + Math.pow(10, (ratingB - ratingA) / 400));
    const expectedB = 1 - expectedA;

    const newRatingA = Math.round(ratingA + kA * (scoreA - expectedA));
    const newRatingB = Math.round(ratingB + kB * ((1 - scoreA) - expectedB));

    return {
      newRatingA: Math.max(ELO.MIN_RATING, Math.min(ELO.MAX_RATING, newRatingA)),
      newRatingB: Math.max(ELO.MIN_RATING, Math.min(ELO.MAX_RATING, newRatingB)),
      changeA: Math.round(newRatingA - ratingA),
      changeB: Math.round(newRatingB - ratingB),
      expectedA: Math.round(expectedA * 1000) / 1000,
      expectedB: Math.round(expectedB * 1000) / 1000,
    };
  }

  static calculateDraw(ratingA, ratingB) {
    return this.calculate(ratingA, ratingB, 0.5);
  }

  static getScoreFromResult(result, playerColor) {
    if (result === '1-0') return playerColor === 'white' ? 1 : 0;
    if (result === '0-1') return playerColor === 'black' ? 1 : 0;
    return 0.5;
  }
}

module.exports = EloService;
