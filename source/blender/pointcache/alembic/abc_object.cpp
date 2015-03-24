/*
 * Copyright 2013, Blender Foundation.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include "abc_mesh.h"
#include "abc_object.h"

extern "C" {
#include "BLI_math.h"

#include "DNA_object_types.h"

#include "BKE_object.h"
}

namespace PTC {

using namespace Abc;
using namespace AbcGeom;

AbcObjectWriter::AbcObjectWriter(const std::string &name, Scene *scene, Object *ob, bool do_mesh, bool do_hair) :
    ObjectWriter(ob, name),
    m_scene(scene),
    m_final_dm(NULL),
    m_dm_writer(0)
{
	if (do_mesh) {
		if (m_ob->type == OB_MESH) {
			m_dm_writer = new AbcDerivedMeshWriter("mesh", ob, &m_final_dm);
		}
	}
}

AbcObjectWriter::~AbcObjectWriter()
{
	if (m_dm_writer)
		delete m_dm_writer;
}

void AbcObjectWriter::init_abc()
{
	if (m_abc_object)
		return;
	
	m_abc_object = abc_archive()->add_id_object<OObject>((ID *)m_ob);
	
	if (m_dm_writer) {
		/* XXX not nice */
		m_dm_writer->init(abc_archive());
		m_dm_writer->init_abc(m_abc_object);
	}
}

#if 0
void AbcObjectWriter::create_refs()
{
	if ((m_ob->transflag & OB_DUPLIGROUP) && m_ob->dup_group) {
		OObject abc_group = abc_archive()->get_id_object((ID *)m_ob->dup_group);
		if (abc_group)
			m_abc_object.addChildInstance(abc_group, "dup_group");
	}
}
#endif

void AbcObjectWriter::write_sample()
{
	if (!m_abc_object)
		return;
	
	if (m_dm_writer) {
		if (abc_archive()->use_render()) {
			m_final_dm = mesh_create_derived_render(m_scene, m_ob, CD_MASK_BAREMESH);
			
			if (m_final_dm) {
				m_dm_writer->write_sample();
				
				m_final_dm->release(m_final_dm);
			}
		}
		else {
			m_final_dm = m_ob->derivedFinal;
			if (!m_final_dm)
				m_final_dm = mesh_get_derived_final(m_scene, m_ob, CD_MASK_BAREMESH);
			
			if (m_final_dm) {
				m_dm_writer->write_sample();
			}
		}
	}
}


AbcObjectReader::AbcObjectReader(const std::string &name, Object *ob) :
    ObjectReader(ob, name)
{
}

void AbcObjectReader::init_abc()
{
	if (m_abc_object)
		return;
	m_abc_object = abc_archive()->get_id_object((ID *)m_ob);
}

PTCReadSampleResult AbcObjectReader::read_sample(float frame)
{
	if (!m_abc_object)
		return PTC_READ_SAMPLE_INVALID;
	
	return PTC_READ_SAMPLE_EXACT;
}

} /* namespace PTC */
