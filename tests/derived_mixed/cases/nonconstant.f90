module statistics_mod
implicit none
integer :: k=7
type :: dt
integer :: a=7,b=k
end type dt
end module

use statistics_mod
implicit none
type(dt) :: x

end
