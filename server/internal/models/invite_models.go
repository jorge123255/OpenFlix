package models

import "time"

// InviteToken stores a single-use family sharing invite.
type InviteToken struct {
	ID        uint       `gorm:"primaryKey"`
	Token     string     `gorm:"size:32;uniqueIndex" json:"token"`
	CreatedBy uint       `gorm:"index" json:"createdBy"`
	ExpiresAt time.Time  `gorm:"index" json:"expiresAt"`
	UsedAt    *time.Time `gorm:"index" json:"usedAt,omitempty"`
	CreatedAt time.Time  `json:"createdAt"`
	UpdatedAt time.Time  `json:"updatedAt"`
}
