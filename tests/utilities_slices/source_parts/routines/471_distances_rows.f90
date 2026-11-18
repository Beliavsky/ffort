function distances_rows(xx) result(xdist)
! compute Euclidean squared distances between rows
real(kind=dp), intent(in) :: xx(:,:)
real(kind=dp)             :: xdist(size(xx,1),size(xx,1))
xdist = sqrt(squared_distances_rows(xx))
end function distances_rows
!
