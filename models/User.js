class User {
  constructor(data) {
    this.id = data.id || null;
    this.name = data.name;
    this.email = data.email;
    this.bio = data.bio || null;
    this.avatar_url = data.avatar_url || null;
    this.created_at = data.created_at || new Date().toISOString();
    this.updated_at = data.updated_at || new Date().toISOString();
  }

  /**
   * Validates email format using regex
   * @returns {boolean} true if email is valid
   */
  validateEmail() {
    if (!this.email) {
      return false;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(this.email);
  }

  /**
   * Validates bio length (max 500 characters)
   * @returns {boolean} true if bio is valid
   */
  validateBio() {
    if (this.bio === null || this.bio === undefined) {
      return true; // Bio is optional
    }
    return this.bio.length <= 500;
  }

  /**
   * Validates name is present
   * @returns {boolean} true if name is valid
   */
  validateName() {
    return this.name && this.name.trim().length > 0;
  }

  /**
   * Validates all fields
   * @returns {object} { isValid: boolean, errors: string[] }
   */
  validate() {
    const errors = [];

    if (!this.validateName()) {
      errors.push('Name is required');
    }

    if (!this.validateEmail()) {
      errors.push('Invalid email format');
    }

    if (!this.validateBio()) {
      errors.push('Bio must not exceed 500 characters');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Converts user to plain object for database storage
   * @returns {object}
   */
  toJSON() {
    return {
      id: this.id,
      name: this.name,
      email: this.email,
      bio: this.bio,
      avatar_url: this.avatar_url,
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }
}

module.exports = User;
