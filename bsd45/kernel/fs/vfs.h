/*
 * vfs.h - a small vnode/VFS layer.
 *
 * Everything that used to be special-cased in the syscall switch (ramfs,
 * ISO9660, tmpfs) now goes through a vnode with an ops vector, so the
 * syscall code no longer knows which file system it is talking to.
 */
#ifndef _VFS_H_
#define _VFS_H_

#define	VREG	1
#define	VDIR	2

struct vnode;

struct vnodeops {
	int	(*lookup)(struct vnode *dv, const char *name,
		    struct vnode **vpp);
	int	(*getattr)(struct vnode *vp, unsigned *mode, unsigned *size);
	int	(*read)(struct vnode *vp, unsigned off, void *buf,
		    unsigned len);
	int	(*write)(struct vnode *vp, unsigned off, const void *buf,
		    unsigned len);
	int	(*readdir)(struct vnode *vp, unsigned *cookie, char *name,
		    int *isdir);
	int	(*create)(struct vnode *dv, const char *name,
		    struct vnode **vpp);
	int	(*remove)(struct vnode *dv, const char *name);
	int	(*mkdir)(struct vnode *dv, const char *name);
	int	(*rmdir)(struct vnode *dv, const char *name);
	int	(*truncate)(struct vnode *vp);
};

struct vnode {
	int			ref;
	int			type;		/* VREG or VDIR */
	struct vnodeops		*ops;
	unsigned		lba;		/* ISO: start sector */
	unsigned		size;		/* ISO: byte size */
	int			node;		/* tmpfs: table slot */
};

extern struct vnode *rootvnode;

void	vfs_init(void);
int	vfs_namei(const char *path, struct vnode **vpp);
int	vfs_lookup_parent(const char *path, struct vnode **dvp, char *name);
int	vfs_create(const char *path, int isdir, struct vnode **vpp);
void	vn_put(struct vnode *vp);

#endif
