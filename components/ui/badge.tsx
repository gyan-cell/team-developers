import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const badgeVariants = cva(
    "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
    {
        variants: {
            variant: {
                default:
                    "border-transparent bg-primary text-background hover:bg-primary/80",
                secondary:
                    "border-transparent bg-surface-highlight text-primary hover:bg-surface-highlight/80",
                destructive:
                    "border-transparent bg-critical text-primary shadow hover:bg-critical/80",
                outline: "text-primary",
                critical: "border-critical/50 bg-critical/10 text-critical",
                high: "border-high/50 bg-high/10 text-high",
                medium: "border-medium/50 bg-medium/10 text-medium",
                low: "border-low/50 bg-low/10 text-low",
            },
        },
        defaultVariants: {
            variant: "default",
        },
    }
)

export interface BadgeProps
    extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> { }

function Badge({ className, variant, ...props }: BadgeProps) {
    return (
        <div className={cn(badgeVariants({ variant }), className)} {...props} />
    )
}

export { Badge, badgeVariants }
