module original_utilities
implicit none
integer,parameter::dp=selected_real_kind(15,307)
real(dp),parameter::tiny_real=1.0d-10
contains
function normalize(xx) result(yy)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx))
yy = xx/max(sum(abs(xx)),tiny_real)
end function normalize
pure function diff_vector_int(xx) result(yy)
integer, intent(in) :: xx(:)
integer             :: yy(size(xx)-1)
integer             :: n
n = size(xx)
if (n > 1) yy = xx(2:)-xx(:n-1)
end function diff_vector_int
pure function diff_vector_real(xx) result(yy)
! return the first differences of xx(:) 
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx)-1)
integer                   :: n
n = size(xx)
if (n > 1) yy = xx(2:)-xx(:n-1)
end function diff_vector_real
pure function diff_matrix_real(xx) result(yy)
! return the difference of consecutive elements for each column of yy(:,:)
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: yy(size(xx,1)-1,size(xx,2))
integer                   :: n
n = size(xx,1)
if (n > 1) yy = xx(2:,:)-xx(:n-1,:)
end function diff_matrix_real
function growing_mean_vec(xx) result(yy)
! compute the cumulative sum of xx(:)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp)             :: yy(size(xx))
real(kind=dp)             :: ysum(size(xx))
integer                   :: i,n
n = size(xx)
if (n < 1) return
ysum(1) = xx(1)
yy(1)   = ysum(1)
do i=2,n
   ysum(i) = ysum(i-1) + xx(i)
   yy(i)   = ysum(i)/i
end do
end function growing_mean_vec
function num_obs_bins(xx,thresh) result(nn)
! count the number of observations in xx(:) in regions defined by ascending thresholds thresh(:)
real(kind=dp), intent(in) :: xx(:)
real(kind=dp), intent(in) :: thresh(:)
integer                   :: nn(size(thresh)+1),i,j,k
nn = 0
do i=1,size(xx)
   j = size(nn)
   do k=1,size(thresh)
      if (xx(i) <= thresh(k)) then
         j = k
         exit
      end if
   end do
   nn(j) = nn(j) + 1
end do
end function num_obs_bins
end module
program p
use original_utilities
implicit none
real(dp)::a(2,2),empty(0)
a(:,1)=[1.0_dp,4.0_dp]
a(:,2)=[8.0_dp,12.0_dp]
print *,normalize([-2.0_dp,3.0_dp,5.0_dp])
print *,diff_vector_int([1,4,10,20])
print *,diff_vector_real([1.0_dp,4.0_dp,10.0_dp]),diff_matrix_real(a)
print *,size(diff_vector_real(empty)),size(diff_vector_int([4])),size(normalize(empty))
print *,growing_mean_vec([2.0_dp,6.0_dp,10.0_dp]),size(growing_mean_vec(empty))
print *,num_obs_bins([-2.0_dp,0.0_dp,1.0_dp,3.0_dp],[0.0_dp,2.0_dp])
end program
